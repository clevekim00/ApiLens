import 'package:flutter/material.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/workflow.dart';
import '../../data/sample_workflows.dart';

class WorkflowTemplateSelector extends StatelessWidget {
  final Function(Workflow template) onSelected;

  const WorkflowTemplateSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final samples = SampleWorkflows.samples;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s3),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.s2),
              Text(
                'Start from Template',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: samples.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _TemplateCard(
                  title: 'Empty Workflow',
                  description: 'Start from scratch',
                  icon: Icons.add_rounded,
                  onTap: () => onSelected(Workflow(
                    id: '',
                    name: 'New Workflow',
                    nodes: [],
                    edges: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  )),
                );
              }
              final sample = samples[index - 1];
              return _TemplateCard(
                title: sample.name,
                description: '${sample.nodes.length} nodes',
                icon: Icons.account_tree_outlined,
                onTap: () => onSelected(sample),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppTokens.s3, bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.primary.withValues(alpha: 0.03),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.s2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppTokens.s3),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
