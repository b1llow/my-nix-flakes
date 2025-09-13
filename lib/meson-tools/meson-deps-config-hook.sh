# shellcheck shell=bash

mesonDepsConfigHook() {
    echo "Executing mesonDepsConfigHook"

    if [ -z "${mesonDeps-}" ]; then
      echo "Error: 'mesonDeps' must be set when using mesonDepsConfigHook."
      exit 1
    fi

    rm -rf subprojects
    ln -s ${mesonDeps} subprojects

    echo "Finished mesonDepsConfigHook"
}

preConfigureHooks+=(mesonDepsConfigHook)