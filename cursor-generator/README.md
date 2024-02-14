# Cursor Generator

A shared script to automate building of cursor themes.

## Usage

this script is used as a git submodule. So if you want to build a cursor theme that uses this script, clone the repository with submodules, e.g.:
`git clone --recurse-submodules https://gitlab.com/zoli111/simp1e.git`.

Do not worry if you forgot the submodules, they will eventually be downloaded before the themes are built.

## Dependencies

The dependencies are `librsvg`, `python-pillow`, and `xcursorgen`.

## How theme building works

* First the script iterates through the color schemes and template SVGs and generates the final theme SVGs.
* Then it iterates through the theme SVGs and builds the actual themes.
* Optionally it creates archives of the themes and exports previews if it was set.

## Theme components

### Template SVGs and color schemes

The template SVGs are located in `src/templatest` directory, and the color schemes are in `src/color_schemes`.

In the template specific cursors or specific parts of cursors have different colors that are replaced depending on the color scheme.
You can add new colors to the templates by editing the SVGs and adding them to `template_colors.txt`. There is only one restriction: the hexadecimal number of a template color must contain at least one letter (a, b, c, d, e, or f), because the script converts the changed colors to uppercase in order to distinguish them from the unchanged ones to avoid unintended color replacing.

You can copy the color schemes, rename them, and change their colors. You can define the colors in RRGGBB format.

### Cursor aliases

Aliases can be set in `names.txt`.

### Sizes

Sizes can be set in `sizes.txt` and as command argument.

## Building themes with the script

Running `build.sh` without any argument will generate all the themes with the default values.

Arguments:

* **--help** or **-h** will show the help message.
* **--sizes=SIZES**: The cursors will be exported in these sizes. Separate them with commas, e.g.: `--sizes=24,32` . Defaults to 24,32,48,64,96. This can also be defined in the sizes.txt.
* **--fps=FPS**: the update frequency of animated cursors. Defaults to 60.
* **--include=template1.svg,template2.svg,color-scheme1.txt**: themes will be generated from only the included templates and color schemes. If not set all templates and color schemes will be used.
* **--exclude=template1.svg,template2.svg,color-scheme1.txt**: Use this to create themes of most of the color schemes and templates, except one or two.
* **--archives** or **-a**: Create archives for easier distribution.
* **--previews** or **-p**: Export preview images of themes.
* **--preview-scale=SCALE**: The scale of preview images. Defaults to 2.

## Thanks

This script uses [this](https://github.com/mxre/cursor) Python program.
