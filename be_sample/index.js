const express = require('express');
const { ApolloServer, gql } = require('apollo-server-express');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const cookieParser = require('cookie-parser');
const cors = require('cors');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET;

// --- Middleware ---
app.use(express.json());
app.use(cookieParser());
app.use(cors({
  origin: true,
  credentials: true
}));

// --- Mock Database ---
const users = [{ id: 1, username: 'admin', password: 'password123' }];
const items = [{ id: 1, name: 'Item 1', value: 'Hello ApiLens' }];

// --- Auth Utilities ---
const generateToken = (user) => jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '1h' });

const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) return res.sendStatus(403);
      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

const authenticateSession = (req, res, next) => {
  const token = req.cookies.session_token;
  if (token) {
    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) return res.sendStatus(403);
      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

// --- REST API Endpoints ---

/**
 * @swagger
 * /auth/login-jwt:
 *   post:
 *     summary: JWT Login
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               username: { type: string }
 *               password: { type: string }
 *     responses:
 *       200:
 *         description: Success
 */
app.post('/auth/login-jwt', (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username && u.password === password);
  if (user) {
    res.json({ token: generateToken(user) });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

/**
 * @swagger
 * /auth/login-session:
 *   post:
 *     summary: Session (Cookie) Login
 *     tags: [Auth]
 *     responses:
 *       200:
 *         description: Cookie set
 */
app.post('/auth/login-session', (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username && u.password === password);
  if (user) {
    const token = generateToken(user);
    res.cookie('session_token', token, { httpOnly: true, secure: false });
    res.json({ message: 'Logged in with session' });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

/**
 * @swagger
 * /api/items:
 *   get:
 *     summary: Get all items (Protected by JWT)
 *     tags: [Data]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of items
 */
app.get('/api/items', authenticateJWT, (req, res) => {
  res.json(items);
});

/**
 * @swagger
 * /api/profile:
 *   get:
 *     summary: Get user profile (Protected by Session)
 *     tags: [Auth]
 *     responses:
 *       200:
 *         description: User info
 */
app.get('/api/profile', authenticateSession, (req, res) => {
  res.json(req.user);
});

// --- GraphQL Setup ---
const typeDefs = gql`
  type Item {
    id: ID!
    name: String!
    value: String!
  }

  type Query {
    hello: String
    getItems: [Item]
  }

  type Mutation {
    addItem(name: String!, value: String!): Item
  }
`;

const resolvers = {
  Query: {
    hello: () => 'Hello from ApiLens Test Server!',
    getItems: () => items,
  },
  Mutation: {
    addItem: (_, { name, value }) => {
      const newItem = { id: items.length + 1, name, value };
      items.push(newItem);
      return newItem;
    },
  },
};

const apolloServer = new ApolloServer({ typeDefs, resolvers });

// --- WebSocket Setup ---
const httpServer = http.createServer(app);
const io = new Server(httpServer, {
  cors: { origin: "*" }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('message', (data) => {
    console.log('Message received:', data);
    socket.emit('response', { text: `Echo: ${data.text}`, timestamp: new Date() });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected');
  });
});

// --- Swagger Documentation ---
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'ApiLens Test Server API',
      version: '1.0.0',
      description: 'A multi-protocol test server for ApiLens',
    },
    servers: [{ url: `http://localhost:${PORT}` }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./index.js'],
};

const swaggerDocs = swaggerJsdoc(swaggerOptions);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

// --- Start Server ---
async function startServer() {
  await apolloServer.start();
  apolloServer.applyMiddleware({ app });

  httpServer.listen(PORT, () => {
    console.log(`🚀 Server ready at http://localhost:${PORT}`);
    console.log(`📊 REST Swagger: http://localhost:${PORT}/docs`);
    console.log(`🧬 GraphQL: http://localhost:${PORT}/graphql`);
    console.log(`🔌 WebSocket: ws://localhost:${PORT}`);
  });
}

startServer();
