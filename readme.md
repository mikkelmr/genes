# genes

An attempt at generating seperate ES6 modules and Typescript definitions from Haxe modules.

## Usage

Install the library and add `-lib genes` to your hxml.

Options:

- add `-D dts` to generate Typescript definition files
- use `-debug` or `-D js-source-map` to generate source maps

## Limitations

This will currently fail at runtime and produce a compiler warning:

- No circular static inits or inheritance

## Alternatives

- Split output with require calls (not bound to above limitations): [hxgenjs](https://github.com/kevinresol/hxgenjs)
- Typescript definition generation: [hxtsdgen](https://github.com/nadako/hxtsdgen)