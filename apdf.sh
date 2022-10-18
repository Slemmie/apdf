# $ ./spdf.sh <input> <output>
# if output is not specified, default output filename is generated
# input file name extensions that are recognized are: ".md" and ".tex"
# required packages:
# - 'inotify-tools'
# - 'texlive'
# - 'texinfo'
# - 'texlive-fonts-recommended'
# - 'texlive-fonts-extra'
# - 'texlive-latex-extra'

# for latex mode: consider following package for european languages: 'texlive-lang-european'
# for latex mode: consider following package for science stuff such as algorithm package: 'texlive-science'

if [ ! -n "$1" ]; then
	echo "[error]: missing input file"
	exit
fi

filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%.*}"

outfile="${filename}.pdf"
if [ $# -lt 2 ]; then
	echo "[info]: missing output file - defaulting to '${outfile}'"
else
	outfile="$2"
fi

if [ "${extension}" = "md" ]; then
	echo "[info]: markdown mode"
	pandoc "$1" -s -o "${outfile}" -V geometry:margin=60px -V fontsize=12pt
	while true; do
		inotifywait -q -e modify "$1"
		echo "[$(date +"%T")]: '$1' was modified..."
		pandoc "$1" -s -o "${outfile}" -V geometry:margin=60px -V fontsize=12pt
	done
elif [ "${extension}" = "tex" ]; then
	echo "[info]: latex mode"
	id=$RANDOM
	int="/tmp/spdf_latex/${id}"
	while [ -d "${int}" ]; do
		id=$RANDOM
	done
	mkdir -p "${int}"
	intpdf="${int}/${filename}.pdf"
	printf "\n\n\n\n" && pdflatex -halt-on-error -output-directory "${int}" "$1" && cp "${intpdf}" "${outfile}"
	while true; do
		inotifywait -q -e modify "$1"
		printf "\n\n\n\n"
		echo "[$(date +"%T")]: '$1' was modified..."
		echo ""
		pdflatex -halt-on-error -output-directory "${int}" "$1" && cp "${intpdf}" "${outfile}"
	done
else
	echo "[info]: unrecognized file extension"
	exit
fi
