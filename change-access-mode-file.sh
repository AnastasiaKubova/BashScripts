
# See more about access mode https://kb.iu.edu/d/abdb.

# Describe:
# This is script for changing access mode for files in directories.

# How to use:
# change-access-mode.sh changeFilesAccessMode $targetFolder $accessMode #fileExtension

changeFilesAccessMode(){

  # Get params.
  targetFolder=$1
  permission=$2
  extension=$3

  # Search filed in folders.
  for file in "$targetFolder"/*
  do
    if [ -d "${file}" ] ; then

      # If the file is folder, then call function again.
      changeFilesAccessMode $file $permission $extension
    else

        # If this is file and ...
        if [ -f "${file}" ]; then

          # ... the file has this extension.
          if [[ $file == *.${extension} ]]; then
            echo "Change mode for file ${file}.";

            # Then change access mode.
            chmod ${permission} "$(dirname "${file}")"
          fi
        else
            echo "${file} is not valid";
            exit 1
        fi
    fi
  done

}

# This is a magic symbol which gives an opportunity call function via console.
"$@"