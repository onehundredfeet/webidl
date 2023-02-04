These files are a basic example of how to set up a new library to use the system


# Steps

1. Create your idl file in lib/
2. Run ./generate.sh to generate the source files
3. Modify CMakeLists.txt with any custom options
3. Run ./setup.sh to configure a build using cmake.  This can be used to make builds with other build systems like Visual studio or Xcode.  This will create a build/TARGET HOST/TARGET ARCHITECTURE/TARGET CONFIG directory to build in.
4. Run ./rebuild.sh for command line builds
5. Run ./install.sh to collect the generated files and put them in the local 'installed' directory.  This directory can be referecned or copied wherever you'd like.

