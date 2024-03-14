import 'package:path/path.dart' as p;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:zef_di_abstractions_generator/src/models/import_path.dart';

import '../models/import_type.dart';

class ImportPathResolver {
  static ImportPath determineImportPath(
      ClassElement element, BuildStep buildStep) {
    final Uri elementUri = element.librarySource.uri;

    if (elementUri.scheme == 'package') {
      final isInternal = elementUri.path.contains('/src/');
      final packagePath = elementUri.pathSegments.skip(1).join('/');
      return ImportPath(
        '${elementUri.pathSegments.first}/$packagePath',
        isInternal ? ImportType.internal : ImportType.package,
      );
    } else {
      final inputPath = buildStep.inputId.uri.path;
      final relativePath =
          p.relative(elementUri.path, from: p.dirname(inputPath));

      return ImportPath(relativePath, ImportType.relative);
    }
  }
}
