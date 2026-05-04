import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../features/workgroup/domain/models/workgroup_model.dart';
import '../../features/workgroup/data/workgroup_repository.dart';
import '../../features/request/models/request_model.dart';
import '../../features/request/data/request_repository.dart';
import '../../features/workflow_editor/domain/models/workflow.dart';
import '../../features/workflow_editor/data/workflow_repository.dart';
import '../../features/workflow_editor/data/sample_workflows.dart';

class DataInitializationService {
  final Ref _ref;

  DataInitializationService(this._ref);

  Future<void> initializeSampleData() async {
    final workgroupRepo = _ref.read(workgroupRepositoryProvider);
    final requestRepo = _ref.read(requestRepositoryProvider);
    final workflowRepo = _ref.read(workflowRepositoryProvider);

    // Only seed if there are no workgroups
    final existingGroups = await workgroupRepo.getAll();
    if (existingGroups.isNotEmpty) return;

    // 1. Create Sample Workgroup
    final sampleGroup = WorkgroupModel.create(
      name: 'Welcome to ApiLens',
      type: WorkgroupType.requestCollection,
      description: 'Check out these samples to get started with API workflows.'
    );
    await workgroupRepo.save(sampleGroup);

    // 2. Create Sample REST Request
    final sampleRequest = RequestModel(
      id: const Uuid().v4(),
      name: 'Get Sample Post',
      method: 'GET',
      url: 'https://jsonplaceholder.typicode.com/posts/1',
      groupId: sampleGroup.id,
    );
    await requestRepo.save(sampleRequest);

    // 3. Create Sample Workflow (from SampleWorkflows)
    for (final sample in SampleWorkflows.samples) {
      final toSave = Workflow(
        id: sample.id,
        name: sample.name,
        groupId: sampleGroup.id,
        nodes: sample.nodes,
        edges: sample.edges,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await workflowRepo.save(toSave);
    }
  }
}

final dataInitializationServiceProvider = Provider((ref) => DataInitializationService(ref));
