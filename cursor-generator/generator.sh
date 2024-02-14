#! /bin/bash

# Check that the path does not contain spaces, symbols and non-ASCII characters

generate_svgs() {
	echo "┌────────────────────────────────────────────────────────┐"
	echo "│  Generating SVGs from color schemes and template SVGs  │"
	echo "└────────────────────────────────────────────────────────┘"
	echo

	mkdir -p generated_svgs

	# Read the values to be replaced into an associative array
	# Lines starting with "#" and emply lines are ignored
	declare -A REPLACEABLE_VALUES
	while read -r LINE
	do
		REPLACEABLE_VALUES["$(echo $LINE | cut -d: -f1)"]="$(echo $LINE | cut -d: -f2)"
	done <<< $(grep -v '^\s*$\|^\s*#' $BASEDIR/template_colors.txt)

	# Create an array for values used to replace the default ones
	declare -A REPLACING_VALUES

	cd $BASEDIR/src/color_schemes
	for COLOR_SCHEME in *.txt
	do
		# If INCLUSION_LIST does not contain .txt files or INCLUSION_LIST contains the color scheme, and EXCLUSION_LIST does not contain it
		if [[ ( ${INCLUSION_LIST[*]} != *.txt* || ${INCLUSION_LIST[*]} == *$COLOR_SCHEME* ) && ${EXCLUSION_LIST[*]} != *$COLOR_SCHEME* ]]
		then
			# Read values from the color scheme file
			while read -r LINE
			do
				REPLACING_VALUES["$(echo $LINE | cut -d: -f1)"]="$(echo $LINE | cut -d: -f2)"
			done <<< $(grep -v '^\s*$\|^\s*#' $BASEDIR/src/color_schemes/$COLOR_SCHEME)

			cd $BASEDIR/src/templates
			for TEMPLATE_SVG in *.svg
			do
				# Same as line 27 but with .svg instead of .txt
				if [[ ( ${INCLUSION_LIST[*]} != *.svg* || ${INCLUSION_LIST[*]} == *$TEMPLATE_SVG* ) && ${EXCLUSION_LIST[*]} != *$TEMPLATE_SVG* ]]
				then
					# Move svg file to generated_svgs directory
					cp $TEMPLATE_SVG $BASEDIR/generated_svgs
					
					echo -n "Applying color scheme to SVG: $TEMPLATE_SVG <- $COLOR_SCHEME... "
					# Replace values with sed
					for KEY in "${!REPLACING_VALUES[@]}"
					do
						if [[ $KEY = "name" ]]
						then
							# If SVG filename is not "cursors.svg" append SVG filename to theme name
							# Get the filename, replace "-" with space, capitalize every first letter of words
							if [[ $TEMPLATE_SVG != cursors.svg ]]
							then
								THEME_NAME_WITH_SVG_NAME="$(echo ${REPLACING_VALUES[$KEY]}) $(echo $TEMPLATE_SVG | cut -f1 -d. | tr '-' ' ' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')"	
							else
								THEME_NAME_WITH_SVG_NAME=$(echo ${REPLACING_VALUES[$KEY]})
							fi
							sed -i "s/${REPLACEABLE_VALUES[$KEY]}/$THEME_NAME_WITH_SVG_NAME/g" $BASEDIR/generated_svgs/$TEMPLATE_SVG
						elif [[ $KEY = "shadow_opacity" ]]
						then
							# Modify the opacity of shadow layer 
							sed -i "$(($(grep -wn 'inkscape:label="shadows"' $BASEDIR/generated_svgs/$TEMPLATE_SVG | cut -d: -f1) + 2))s/opacity:${REPLACEABLE_VALUES[$KEY]}/opacity:${REPLACING_VALUES[$KEY]}/" \
							$BASEDIR/generated_svgs/$TEMPLATE_SVG
						else
							# Normally replace anything else
							sed -i "s/${REPLACEABLE_VALUES[$KEY]}/${REPLACING_VALUES[$KEY]^^}/g" $BASEDIR/generated_svgs/$TEMPLATE_SVG
						fi
					done

					# Name the cursor theme
					mv -f $BASEDIR/generated_svgs/$TEMPLATE_SVG $BASEDIR/generated_svgs/$(echo $THEME_NAME_WITH_SVG_NAME | sed -e 's/[^A-Za-z0-9_-]/-/g').svg
				fi

				echo "done"
				echo

				cd $BASEDIR/src/templates
			done

			# Empty this array
			REPLACING_VALUES=()
		fi

		cd $BASEDIR/src/color_schemes
	done
} # generate_svgs()

build_themes() {
	echo "┌────────────────────────────────────┐"
	echo "│  Building cursor themes from SVGs  │"
	echo "└────────────────────────────────────┘"
	echo

	mkdir -p $BASEDIR/built_themes

	cd $BASEDIR/generated_svgs

	for GENERATED_SVG in *.svg
	do
		# Cut off the extension from filename
		THEME_NAME=$(echo $GENERATED_SVG | cut -f1 -d.)

		echo -n "Building $THEME_NAME... "
		
		cd $BASEDIR

		# Generate the theme using the python script from mxre
		python3 $BASEDIR/cursor-generator/make.py $BASEDIR/generated_svgs/$GENERATED_SVG -n $THEME_NAME -o $BASEDIR/built_themes/$THEME_NAME --force \
			--fps $( [[ -z $FPS ]] && echo 60 || echo $FPS) \
			$( [[ -z $SIZES ]] || echo "--sizes $SIZES" )

		echo "done"

		# Create archives
		if [[ $ARCHIVES = 1 ]]
		then
			echo -n "Creating archive... "

			cd $BASEDIR/built_themes
			tar -cJf $BASEDIR/built_themes/$THEME_NAME.tar.xz $THEME_NAME

			echo "done"
		fi

		# Export previews
		if [[ $PREVIEWS = 1 ]]
		then
			echo -n "Exporting preview... "

			cd $BASEDIR/generated_svgs

			# Get the number next line to "id="background_placeholder""
			BG_WITH=$(grep -A 2 'id="background_placeholder"' $GENERATED_SVG | awk -F'"' 'NR==2 {print $2}')
			BG_HEIGHT=$(grep -A 2 'id="background_placeholder"' $GENERATED_SVG | awk -F'"' 'NR==3 {print $2}')
			# Use background_image if there is no background_placeholder
			if [[ $BG_WITH = "" ]]
			then
				BG_WITH=$(grep -A 2 'id="background_image"' $GENERATED_SVG | awk -F'"' 'NR==2 {print $2}')
				BG_HEIGHT=$(grep -A 2 'id="background_image"' $GENERATED_SVG | awk -F'"' 'NR==3 {print $2}')
			fi
			
			
			# If PREVIEW_SCALE is unset, set to 2
			[[ -z $PREVIEW_SCALE ]] && PREVIEW_SCALE=2

						
			sed -i "$(($(grep -wn 'inkscape:label="background"' $GENERATED_SVG | cut -d: -f1) + 2))s/display:none/display:inline/" $GENERATED_SVG

			rsvg-convert $GENERATED_SVG --page-width $(($BG_WITH * $PREVIEW_SCALE)) --page-height $(($BG_HEIGHT * $PREVIEW_SCALE)) -z $PREVIEW_SCALE \
				-o $BASEDIR/previews/$(basename $GENERATED_SVG | cut -f 1 -d.).png

			sed -i "$(($(grep -wn 'inkscape:label="background"' $GENERATED_SVG | cut -d: -f1) + 2))s/display:inline/display:none/" $GENERATED_SVG

			echo "done"

			cd $BASEDIR
		fi

		echo

		cd $BASEDIR/generated_svgs
	done

	if [[ $ARCHIVES = 1 ]]
	then

		THEME_NAME_ALL=$(basename $BASEDIR)

		echo -n "Creating archive of all themes: ${THEME_NAME_ALL^}-All.tar.xz... "

		cd $BASEDIR/built_themes
		tar -cJf $BASEDIR/built_themes/${THEME_NAME_ALL^}-All.tar.xz --exclude=*.tar.xz *

		echo "done"
		echo
	fi
} # build_themes()

show_help() {
	echo "Arguments:

  --help | -h
    Show this message


Theme settings

  --fps=FPS
    How many times animated cursors should update per second, defaults to 60

  --sizes=SIZES
    The cursors will be exported in these sizes, separate them with a single comma, default is 24,32,48,64,96


Options to not generate all themes

  --include=TEMPLATES,COLOR_SCHEMES
    Themes will only be created from the templates and color schemes specified in this list, if not set, themes will be created from all templates and color schemes

  --exclude=TEMPLATES,COLOR_SCHEMES
    Use this to create themes from most of the color schemes and templates, except one or two


Useful options if you are developing themes for others

  --archives | -a
    Create archives of the themes for easier distributing

  --previews | -p
    Export images of the themes

  --preview-scale=SCALE
    The scale of the preview images, defaults to 2
"
} #show_help()

while [[ $1 != "" ]]; do
	case $1 in
		-a | --archives)
			ARCHIVES=1
		;;
		-p | --previews)
			PREVIEWS=1
			mkdir -p $BASEDIR/previews
		;;
		--preview-scale=*)
			PREVIEW_SCALE=${1:16}
		;;
		--fps=*)
			FPS=${1:6}
		;;
		--sizes=*)
			SIZES=${1:8}
		;;
		--include=*)
			read -r -a INCLUSION_LIST <<< "${1:10}"
		;;
		--exclude=*)
			read -r -a EXCLUSION_LIST <<< "${1:10}"
		;;
		-h | --help)
			show_help
			exit
		;;
		*)
	esac
	shift
done

cd $BASEDIR

echo
echo "┌───────────────────────────────┐"
echo "│  Checking build dependencies  │"
echo "└───────────────────────────────┘"
echo

python3 -c 'import PIL.Image' 1>/dev/null 2>/dev/null && { echo "Python-Pillow is installed"; echo; } || { echo "Python-Pillow cannot be found. Please install Python Pillow, and try again."; exit; }
rsvg-convert --help 1>/dev/null 2>/dev/null && { echo "Rsvg-Convert is installed"; echo; } || { echo "Rsvg-Convert cannot be found. Please install Rsvg-Convert, and try again."; exit; }
xcursorgen --help 1>/dev/null 2>/dev/null && { echo "Xcursorgen is installed"; echo; } || { echo "Xcursorgen cannot be found. Please install Xcursorgen, and try again."; exit; }

[[ -f $BASEDIR/sizes.txt && -z $SIZES ]] && SIZES=$(cat $BASEDIR/sizes.txt)

generate_svgs
build_themes

echo "All themes are finished. :)"
