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

macro (_import_library_from_extproject library_target location extproj)

    add_library (${library_target} STATIC IMPORTED GLOBAL)
    set_target_properties (${library_target}
                           PROPERTIES IMPORTED_LOCATION ${location})
    add_dependencies (${library_target} ${extproj})

endmacro (_import_library_from_extproject)

# Workaround for some generators setting a different output directory
function (_get_build_directory_suffix_for_generator SUFFIX)

    if (${CMAKE_GENERATOR} STREQUAL "Xcode")

        if (CMAKE_BUILD_TYPE)

            set (${SUFFIX} ${CMAKE_BUILD_TYPE} PARENT_SCOPE)

        else (CMAKE_BUILD_TYPE)

            set (${SUFFIX} "Debug" PARENT_SCOPE)

        endif (CMAKE_BUILD_TYPE)

    endif (${CMAKE_GENERATOR} STREQUAL "Xcode")

endfunction (_get_build_directory_suffix_for_generator)

macro (_append_cache_definition CACHE_OPTION VALUE CACHE_ARGUMENT_LINE)

    if (DEFINED ${VALUE})
        list (APPEND ${CACHE_ARGUMENT_LINE}
              "-D${CACHE_OPTION}:string=${${VALUE}}")
    endif (DEFINED ${VALUE})

endmacro (_append_cache_definition)

macro (_append_cache_library_path CACHE_OPTION LIBRARY CACHE_ARGUMENT_LINE)

    if (DEFINED ${LIBRARY})

        get_property (_location TARGET ${${LIBRARY}} PROPERTY LOCATION)

        # If a location is set, we should use that one, otherwise
        # just pass the linker line of the library.
        if (_location)
            list (APPEND ${CACHE_OPTION}
                  "-D${CACHE_ARGUMENT_LINE}:string=${_location}")
        else (_location)
            list (APPEND ${CACHE_OPTION}
                  "-D${CACHE_ARGUMENT_LINE}:string=${${VALUE}}")
        endif (_location)

    endif (DEFINED ${LIBRARY})

endmacro (_append_cache_library_path)

macro (_append_external_project_deps LIBRARY EXTERNAL_PROJECTS)

    if (DEFINED ${LIBRARY})

        get_property (_external_project
                      TARGET ${${LIBRARY}} PROPERTY EXTERNAL_PROJECT)

        # If a location is set, we should use that one, otherwise
        # just pass the linker line of the library.
        if (_external_project)
            list (APPEND ${EXTERNAL_PROJECTS} ${_external_project})
        endif (_external_project)

    endif (DEFINED ${LIBRARY})

endmacro (_append_external_project_deps)

macro (_append_extproject_variables LIBRARY
                                    CACHE_ARGUMENT_LINE
                                    EXTERNAL_PROJECTS
                                    CACHE_OPTION)

    _append_cache_library_path (${CACHE_OPTION}
                                ${LIBRARY}
                                ${CACHE_ARGUMENT_LINE})
    _append_external_project_deps (${LIBRARY}
                                   ${EXTERNAL_PROJECTS})

endmacro (_append_extproject_variables)

if (CPP_SUBPROCESS_EXTERNAL_SET_INCLUDE_DIRS AND
    CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY_DIRS AND
    CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY)

    set (CPP_SUBPROCESS_FOUND 1)

endif (CPP_SUBPROCESS_EXTERNAL_SET_INCLUDE_DIRS AND
       CPP_SUBPROCESS_EXTERNAL_SET_LIBRARY_DIRS AND
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
    set (CPP_SUBPROCESS_CACHE_DEFINITIONS)
    set (CPP_SUBPROCESS_PROJECT_DEPENDENCIES)
    _append_cache_definition (GTEST_EXTERNAL_SET_INCLUDE_DIR
                              GTEST_INCLUDE_DIR
                              CPP_SUBPROCESS_CACHE_DEFINITIONS)
    _append_cache_definition (GMOCK_EXTERNAL_SET_INCLUDE_DIR
                              GMOCK_INCLUDE_DIR
                              CPP_SUBPROCESS_CACHE_DEFINITIONS)

    _append_extproject_variables (GTEST_LIBRARY
                                  GTEST_EXTERNAL_SET_LIBRARY
                                  CPP_SUBPROCESS_PROJECT_DEPENDENCIES
                                  CPP_SUBPROCESS_CACHE_DEFINITIONS)
    _append_extproject_variables (GMOCK_LIBRARY
                                  GMOCK_EXTERNAL_SET_LIBRARY
                                  CPP_SUBPROCESS_PROJECT_DEPENDENCIES
                                  CPP_SUBPROCESS_CACHE_DEFINITIONS)
    _append_extproject_variables (GTEST_MAIN_LIBRARY
                                  GTEST_EXTERNAL_SET_MAIN_LIBRARY
                                  CPP_SUBPROCESS_PROJECT_DEPENDENCIES
                                  CPP_SUBPROCESS_CACHE_DEFINITIONS)
    _append_extproject_variables (GMOCK_MAIN_LIBRARY
                                  GMOCK_EXTERNAL_SET_MAIN_LIBRARY
                                  CPP_SUBPROCESS_PROJECT_DEPENDENCIES
                                  CPP_SUBPROCESS_CACHE_DEFINITIONS)

    # Get the EXTERNAL_PROJECT property for the Google Mock library
    # append that as the dependency, otherwise just don't add it
    # and the relevant Find* macros will do the right thing.
    get_property (GMOCK_LIBRARY_EXTERNAL_PROJECT
                  TARGET ${GMOCK_LIBRARY}
                  PROPERTY EXTERNAL_PROJECT)

    if (GMOCK_LIBRARY_EXTERNAL_PROJECT)
        _append_cache_definition (GTEST_AND_GMOCK_EXTERNAL_SET_DEPENDENCY
                                  GMOCK_LIBRARY_EXTERNAL_PROJECT
                                  CPP_SUBPROCESS_CACHE_DEFINITIONS)
    endif (GMOCK_LIBRARY_EXTERNAL_PROJECT)

    ExternalProject_Add (${EXTPROJECT_TARGET}
                         DEPENDS ${CPP_SUBPROCESS_PROJECT_DEPENDENCIES}
                         URL ${CPP_SUBPROCESS_SOURCES_DIRECTORY}
                         PREFIX ${CPP_SUBPROCESS_PREFIX}
                         CMAKE_CACHE_ARGS ${CPP_SUBPROCESS_CACHE_DEFINITIONS}
                         INSTALL_COMMAND "")

    set (CPP_SUBPROCESS_LIBRARY polysquare_cpp_subprocess)

    set (BINARY_DIR_SUFFIX)

    _get_build_directory_suffix_for_generator (BINARY_DIR_SUFFIX)

    set (_library_name libpolysquare_cpp_subprocess.a)
    set (CPP_SUBPROCESS_LIBRARY_PATH
         ${CPP_SUBPROCESS_OUTPUT_BINARY_DIR}/${BINARY_DIR_SUFFIX}/${_library_name})

    set (CPP_SUBPROCESS_INCLUDE_DIR ${CPP_SUBPROCESS_SOURCE_DIR}/include)

    # Tell CMake that we've imported some libraries
    _import_library_from_extproject (${CPP_SUBPROCESS_LIBRARY}
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
