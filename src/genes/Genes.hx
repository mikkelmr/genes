package genes;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
import genes.util.PathUtil;
import genes.util.TypeUtil;

using haxe.macro.TypeTools;
using Lambda;

private typedef ImportedModule = {
  name: String,
  importExpr: Expr,
  types: Array<{name: String, type: haxe.macro.Type}>
}
#end

class Genes {
  macro public static function dynamicImport<T, R>(expr: ExprOf<T->
    R>): ExprOf<js.lib.Promise<R>> {
    final pos = Context.currentPos();

    return switch expr.expr {
      case EFunction(_, {args: args, expr: body}):
        final current = Context.getLocalClass().get().module;
        final ret = Context.typeExpr(body).t.toComplexType();

        final modules:Array<ImportedModule> = [];

        for (arg in args) {
          final name = arg.name;
          final type = Context.getType(name);
          final module = TypeUtil.moduleTypeName(TypeUtil.typeToModuleType(type));

          switch modules.find(m -> m.name == module) {
            case null:
              modules.push({
                name: module,
                importExpr: {
                  final path = PathUtil.relative(current.replace('.', '/'),
                    module.replace('.', '/'));
                  macro js.Syntax.code('import({0})', $v{path});
                },
                types: [
                  {
                    name: name,
                    type: type
                  }
                ]
              });
            case module:
              module.types.push({name: name, type: type});
          }
        }

        final e = switch modules {
          case [module]:
            final setup = [
              for (sub in module.types)
                macro js.Syntax.code($v{'var ${sub.name} = module.${sub.name}'})
            ];

            // generate ignore/ignoreMultiple depending on the number of types
            final ignore = switch module.types {
              case [sub]:
                body -> macro genes.Genes.ignore($v{sub.name}, $body);
              case types:
                final list = [for (sub in types) macro $v{sub.name}];
                body -> macro genes.Genes.ignoreMultiple($a{list}, $body);
            }

            final handler = ignore(macro function(module) {
              @:mergeBlock $b{setup};
              $body;
            });

            macro ${module.importExpr}.then($handler);

          default:
            final setup = [];
            final ignores = [];

            for (i in 0...modules.length) {
              for (sub in modules[i].types) {
                setup.push(macro js.Syntax.code($v{'var ${sub.name} = modules[$i].${sub.name}'}));
                ignores.push(macro $v{sub.name});
              }
            }

            final imports = macro $a{modules.map(module -> module.importExpr)};
            macro js.lib.Promise.all($imports)
              .then(genes.Genes.ignoreMultiple($a{ignores}, function(modules) {
                @:mergeBlock $b{setup};
                $body;
              }));
        }

        macro($e : js.lib.Promise<$ret>);

      default:
        Context.error('Cannot import', expr.pos);
    }
  }

  public static function ignore<T>(name: String, res: T)
    return res;

  public static function ignoreMultiple<T>(name: Array<String>, res: T)
    return res;
}
