package genes;

import haxe.macro.Type;

enum TypeAccessorImpl {
  Concrete(module: String, path: String);
  Abstract(name: String);
}

abstract TypeAccessor(TypeAccessorImpl) from TypeAccessorImpl {
  @:from public static function fromModuleType(type: ModuleType): TypeAccessor {
    return switch type {
      case TAbstract(_.get() => cl = {meta: meta, name: name}):
        switch meta.has(':coreType') {
          // Todo: I believe haxe was to cancel use of Abstract types as value
          case true: Abstract('"$$hxCoreType__$name"');
          case false: throw 'assert';
        }
      case TClassDecl((_.get() : BaseType) => base) | TEnumDecl((_.get() : BaseType) => base) | TTypeDecl((_.get() : BaseType) => base):
        fromBaseType(base);
    }
  }

  @:from public static function fromBaseType(type: BaseType): TypeAccessor {
    final dependency = Dependencies.makeDependency(type);
    if (dependency == null)
      return Concrete(type.module, type.name);
    return Concrete(dependency.path, dependency.name);
  }
}