import '../models/registrations.dart';

class SortHelper {
  static List<RegistrationData> topologicallySortRegistrations(
      List<RegistrationData> registrations) {
    // Build the graph from InstanceData dependencies
    final Map<String, Set<String>> graph = {};
    final Map<String, RegistrationData> dataLookup = {};

    // Initialize graph and lookup table
    for (var registration in registrations) {
      if (registration is InstanceData) {
        graph[registration.className] = registration.dependencies.toSet();
      }
      dataLookup[registration.className] = registration;
    }

    // Perform topological sort
    final List<String> sortedClassNames = performTopologicalSort(graph);

    // Map sorted class names back to their corresponding RegistrationData objects
    final List<RegistrationData> sortedRegistrations = [];
    for (var className in sortedClassNames) {
      final registrationData = dataLookup[className];
      if (registrationData != null) {
        sortedRegistrations.add(registrationData);
      } else {
        // Optionally, handle the missing data case, such as logging a warning
        // This can help identify why a className was not found in dataLookup
        print("Warning: No registration data found for class '$className'");
      }
    }

    // Add FactoryData objects at the end, assuming they don't have dependencies affecting the order
    for (var registration in registrations) {
      if (registration is FactoryData &&
          !sortedClassNames.contains(registration.className)) {
        sortedRegistrations.add(registration);
      }
    }

    return sortedRegistrations;
  }

  static List<String> performTopologicalSort(Map<String, Set<String>> graph) {
    final List<String> sorted = [];
    final Set<String> visited = {};
    final Set<String> visiting = {};

    void visit(String node) {
      if (visited.contains(node)) return;
      if (visiting.contains(node)) {
        throw Exception('Cyclic dependency detected in $node');
      }

      visiting.add(node);
      // Ensure there's a list for 'node' in the graph, even if it's empty
      final dependencies = graph[node];
      if (dependencies != null) {
        for (var dep in dependencies) {
          visit(dep);
        }
      }
      visiting.remove(node);
      visited.add(node);
      sorted.add(node);
    }

    graph.keys.forEach(visit);
    return sorted;
  }
}
