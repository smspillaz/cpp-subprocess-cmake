# FindCPPSubprocess.cmake
#
# This CMake script will search for or add an external project target
# for Polysquare's CPPSubprocess library.
#
# CPP_SUBPROCESS_FOUND       : Whether or not CPPSubprocess was
#                              available on the system.
# CPP_SUBPROCESS_INCLUDE_DIR : Include directory containing gtest/gtest.h
# CPP_SUBPROCESS_LIBRARY     : Linker line for the CPPSubproces library.
#
# There are two mechanism by which we would find the library and related
# header files.
#
# 1. The user provided them to us by setting the options
#    CPP_SUBPROCESS_EXTERNAL_SET_INCLUDE_DIR
#    CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY_DIR
#    CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY
#
# 2. We import an external project using ExternalProject_Add
#    from the path specified in
#    CPP_SUBPROCESS_SOURCES_DIRECTORY
#
#    If this variable is not set, an error will be raised.

include (imported-project-utils/ImportedProjectUtils)

if (CPP_SUBPROCESS_EXTERNAL_SET_INCLUDE_DIRS AND
    CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY)

    set (CPP_SUBPROCESS_INCLUDE_DIR ${CPP_SUBPROCESS_EXTERNAL_SET_INCLUDE_DIR})
    set (CPP_SUBPROCESS_LIBRARY polysquare_cpp_subprocess)

    polysquare_import_utils_import_library (${CPP_SUBPROCESS_LIBRARY} STATIC
                                            ${CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY})

    set (CPP_SUBPROCESS_FOUND 1)

endif (CPP_SUBPROCESS_EXTERNAL_SET_INCLUDE_DIRS AND
       CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY)

if (NOT CPP_SUBPROCESS_FOUND)

    if (NOT DEFINED CPP_SUBPROCESS_SOURCES_DIRECTORY)
        message (SEND_ERROR "CPP_SUBPROCESS_SOURCES_DIRECTORY must be defined "
                 "in order to use find cpp-subprocess")
        return ()
    endif (NOT DEFINED CPP_SUBPROCESS_SOURCES_DIRECTORY)

    include (ExternalProject)

    set (BIN_DIR ${CMAKE_CURRENT_BINARY_DIR})

    set (CPP_SUBPROCESS_EXT_PROJECT_NAME CPPSubprocess)
    set (CPP_SUBPROCESS_PREFIX ${BIN_DIR}/__polysquare_cpp_subprocess)
    set (CPP_SUBPROCESS_SOURCE_DIR
         ${CPP_SUBPROCESS_PREFIX}/src/${CPP_SUBPROCESS_EXT_PROJECT_NAME})
    set (CPP_SUBPROCESS_DEFAULT_BINARY_DIR
         ${CPP_SUBPROCESS_SOURCE_DIR}-build)
    set (CPP_SUBPROCESS_OUTPUT_BINARY_DIR
         ${CPP_SUBPROCESS_DEFAULT_BINARY_DIR}/src)

    set (EXTPROJECT_TARGET CPPSubprocess)

    # Pass definitions for other external libraries if they were already defined
    # That means the definitions for Google Mock.
    set (CACHE_DEFINITIONS)
    set (PROJECT_DEPENDENCIES)
    google_mock_get_cache_lines_and_deps_from_found (CACHE_DEFINITIONS
                                                     PROJECT_DEPENDENCIES)

    ExternalProject_Add (${EXTPROJECT_TARGET}
                         URL ${CPP_SUBPROCESS_SOURCES_DIRECTORY}
                         PREFIX ${CPP_SUBPROCESS_PREFIX}
                         CMAKE_CACHE_ARGS ${CACHE_DEFINITIONS}
                         INSTALL_COMMAND "")

    add_dependencies (${EXTPROJECT_TARGET}
                      ${PROJECT_DEPENDENCIES})

    set (CPP_SUBPROCESS_LIBRARY polysquare_cpp_subprocess)

    set (SUFFIX)
    polysquare_import_utils_get_build_suffix_for_generator (SUFFIX)

    set (_library_name libpolysquare_cpp_subprocess.a)
    set (CPP_SUBPROCESS_LIBRARY_PATH
         ${CPP_SUBPROCESS_OUTPUT_BINARY_DIR}/${SUFFIX}/${_library_name})

    set (CPP_SUBPROCESS_INCLUDE_DIR ${CPP_SUBPROCESS_SOURCE_DIR}/include)

    # Tell CMake that we've imported some libraries
    polysquare_import_utils_library_from_extproject (${CPP_SUBPROCESS_LIBRARY}
                                                     STATIC
                                                     ${CPP_SUBPROCESS_LIBRARY_PATH}
                                                     ${EXTPROJECT_TARGET})

    set (CPP_SUBPROCESS_FOUND 1)

endif (NOT CPP_SUBPROCESS_FOUND)

if (NOT CPP_SUBPROCESS_FOUND)

    if (CPPSubprocess_FIND_REQUIRED)

        message (SEND_ERROR "Could not find Polysquare cpp-subprocess")

    endif (GoogleMock_FIND_REQUIRED)

else (NOT CPP_SUBPROCESS_FOUND)

    if (NOT CPPSubprocess_FIND_QUIETLY)

        message (STATUS "Polysquare cpp-subprocess Found")

    endif (NOT CPPSubprocess_FIND_QUIETLY)

endif (NOT CPP_SUBPROCESS_FOUND)
