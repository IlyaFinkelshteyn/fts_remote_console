-- LICENSE
--
--   This software is dual-licensed to the public domain and under the following 
--   license: you are granted a perpetual,   irrevocable license to copy, modify, 
--   publish, and distribute this file as you see fit.



ROOT_DIR = path.getabsolute("../..")
SLN_DIR = path.join(ROOT_DIR, "projects", _ACTION)

PLATFORMS = { "x32", "x64" }
BUILDS = { "debug", "release" }

if (_ACTION and not string.startswith(_ACTION, "vs")) then
    SLN_DIR = SLN_DIR.."_"..os.get()
end


-----------------------------------
function fts_project(project_name)

        configuration {}

        objdir (path.join(SLN_DIR, "build"))

        configuration "debug"
            defines { "DEBUG" }
            flags { "Symbols" }

        configuration "release"
            defines { "NDEBUG" }
            flags { "Optimize" }

        configuration "windows"
            defines { 
                "FTS_WINDOWS", 
                "_WIN32_WINNT=0x0601",  -- Windows 7 minimum
            }

        configuration "linux"
            defines { "FTS_LINUX" }
            buildoptions_cpp { "-std=c++11", }

        configuration "macosx"
            defines { "FTS_OSX" }
            buildoptions_cpp { "-std=c++11", }

        for i, platform in ipairs(PLATFORMS) do
            for j, build in ipairs(BUILDS) do
                configuration { platform, build }
                targetdir (path.join(SLN_DIR, "bin", platform .. "_" .. build, project_name))
            end
        end

        configuration {}
end


-----------------------------------
solution "fts_console"
    configurations (BUILDS)
    platforms (PLATFORMS)
    location (SLN_DIR)


   -----------------------------------
    project "fts_remote_console"

        kind "WindowedApp"
        language "C++"
        location (path.join(SLN_DIR, "projects"))
        flags { "ExtraWarnings", "NoEditAndContinue" }

        files {
            path.join(ROOT_DIR, "code/remote_console/*.h"),
            path.join(ROOT_DIR, "code/remote_console/*.cpp"),
            path.join(ROOT_DIR, "code/lib_fts/*.h"),
            path.join(ROOT_DIR, "code/lib_fts/*.cpp"),
        }

        includedirs {
            path.join(ROOT_DIR, "code/thirdparty"),
            path.join(ROOT_DIR, "code/thirdparty/asio"),
            path.join(ROOT_DIR, "code/thirdparty/imgui"),
            path.join(ROOT_DIR, "code/thirdparty/glfw/include"),
            path.join(ROOT_DIR, "code") 
        }

        links {
            -- internal
            "imgui",
            "glfw",
            "flatbuffers",
            "net",
        }

        defines {
            "ASIO_STANDALONE"
        }

        configuration "windows"
            links {
                "ws2_32",
                "shcore",
                "opengl32"
            }

        configuration "linux"
            links {
                "GL",
                "glut",
                "Xrandr",
                "Xinerama",
                "Xcursor",
            }

        configuration "macosx"
            linkoptions {
                "-framework Cocoa",
                "-framework IOKit",
                "-framework CoreFoundation",
                "-framework CoreVideo",
                "-framework OpenGL",
            }

        fts_project("fts_remote_console")

    -----------------------------------
    project "example_game"

        kind "ConsoleApp"
        language "C++"
        location (path.join(SLN_DIR, "projects"))
        flags { "ExtraWarnings", "NoEditAndContinue" }

        files {
            path.join(ROOT_DIR, "code/example_game/*.h"),
            path.join(ROOT_DIR, "code/example_game/*.cpp"),
        }

        includedirs {
            path.join(ROOT_DIR, "code/thirdparty"),
            path.join(ROOT_DIR, "code/thirdparty/asio"),
            path.join(ROOT_DIR, "code") 
        }

        links {
            "flatbuffers",
            "net",
        }

        defines {
            "ASIO_STANDALONE"
        }

        -- external
        configuration "windows"
            links {
                "ws2_32",
            }

        configuration "linux"
            links {
                "pthread"
            }

        fts_project("example_game")


    -----------------------------------
    project "protocol"

        kind "StaticLib"
        language "C++"
        location (path.join(SLN_DIR, "projects"))
        flags { "NoEditAndContinue" }

        -- $FTS Want fbs files marked as "Custom Build Tool" in VS
        files { 
            path.join(ROOT_DIR, "code/protocol/**.fbs"),
            path.join(ROOT_DIR, "code/protocol/**.h"),
            path.join(ROOT_DIR, "code/protocol/**.cpp"),
        }

        -- $$$FTS want to generate these automatically from **.fbs
        files {
            path.join(ROOT_DIR, "code/protocol/protocol_generated.h"),
        }

        includedirs { 
            path.join(ROOT_DIR, "code/thirdparty"),
        }

        links {
            -- built from solution
            "flatbuffers",
        }
        
        -- Execute flatc (compiled by flatbuffers project) to read .fbs files and generate C++ code
        for i, platform in ipairs(PLATFORMS) do
            for j, build in ipairs(BUILDS) do
                configuration { platform, build, "vs*" }
                    prebuildcommands { "$(SolutionDir)bin/"..platform.."_"..build.."/flatbuffers/flatc ".."--cpp --scoped-enums -o ../../../code/protocol/ ../../../code/protocol/protocol.fbs" }
                configuration { platform, build, "not vs*" }
                   prebuildcommands { "../bin/"..platform.."_"..build.."/flatbuffers/flatc ".."--cpp --scoped-enums -o ../../../code/protocol/ ../../../code/protocol/protocol.fbs" }
            end
        end

        fts_project("protocol")


    -----------------------------------
    project "net"

        kind "StaticLib"
        language "C++"
        location (path.join(SLN_DIR, "projects"))
        flags { "NoEditAndContinue" }

        files { 
            path.join(ROOT_DIR, "code/net/**.h"),
            path.join(ROOT_DIR, "code/net/**.cpp"),
            path.join(ROOT_DIR, "code/thirdparty/asio/**.hpp"),
            path.join(ROOT_DIR, "code/thirdparty/asio/**.ipp"),
        }

        includedirs { 
            path.join(ROOT_DIR, "code/thirdparty"),
            path.join(ROOT_DIR, "code/thirdparty/asio"),
            path.join(ROOT_DIR, "code"),
        }

        links {
            -- built from solution
            "protocol",
        }

        defines {
            "ASIO_STANDALONE"
        }

        fts_project("net")


        
   -----------------------------------
    group "thirdparty"
      
       -----------------------------------
        project "flatbuffers"

            kind "ConsoleApp"
            language "C++"
            targetname "flatc"
            location (path.join(SLN_DIR, "projects"))
            flags { "NoEditAndContinue" }

            files { 
                path.join(ROOT_DIR, "code/thirdparty/flatbuffers/**.h"),
                path.join(ROOT_DIR, "code/thirdparty/flatbuffers/**.cpp"),
            }

            includedirs { 
                path.join(ROOT_DIR, "code/thirdparty"), 
            }

            defines {
                "FLATBUFFERS_TRACK_VERIFIER_BUFFER_SIZE"
            }

            fts_project("flatbuffers")


        -----------------------------------
        project "glfw"

            kind "StaticLib"
            language "C++"
            location (path.join(SLN_DIR, "projects"))
            flags { "NoEditAndContinue" }

            glfw_include = path.join(ROOT_DIR, "code/thirdparty/glfw/include")
            glfw_src = path.join(ROOT_DIR, "code/thirdparty/glfw/src")

            files { 
                path.join(glfw_include, "code/thirdparty/glfw/include/**.h"),

                path.join(glfw_src, "**.h"),
                path.join(glfw_src, "**.c"),
                path.join(glfw_src, "**.m"),
            }

            includedirs { 
                path.join(ROOT_DIR, "code/thirdparty"), 
            }

            configuration "windows"
                excludes {
                    path.join(glfw_src, "linux**"),
                    path.join(glfw_src, "cocoa**"),
                    path.join(glfw_src, "posix**"),
                    path.join(glfw_src, "x11**"),
                    path.join(glfw_src, "glx**"),
                    path.join(glfw_src, "mir**"),
                    path.join(glfw_src, "wl**"),
                    path.join(glfw_src, "xkb**"),
                    path.join(glfw_src, "osmesa**"),
                    path.join(glfw_src, "nsgl**"),
                }

                defines {
                    "_GLFW_WIN32",
                    "_CRT_SECURE_NO_WARNINGS"
                }

            configuration "linux"
                excludes {
                    path.join(glfw_src, "win32**"),
                    path.join(glfw_src, "cocoa**"),
                    path.join(glfw_src, "mir**"),
                    path.join(glfw_src, "wl**"),
                    path.join(glfw_src, "wgl**"),
                    path.join(glfw_src, "osmesa**"),
                    path.join(glfw_src, "nsgl**"),
                }

                defines {
                    "_GLFW_X11"
                }

            configuration "macosx"
                excludes {
                    path.join(glfw_src, "win32**"),
                    path.join(glfw_src, "linux**"),
                    path.join(glfw_src, "x11**"),
                    path.join(glfw_src, "glx**"),
                    path.join(glfw_src, "mir**"),
                    path.join(glfw_src, "wl**"),
                    path.join(glfw_src, "xkb**"),
                    path.join(glfw_src, "wgl**"),
                    path.join(glfw_src, "osmesa**"),
                    path.join(glfw_src, "posix_time**"),
                }

                defines {
                    "_GLFW_COCOA",
                    "GLFW_USE_RETINA",
                    "GLFW_USE_CHDIR",
                    "GLFW_USE_MENUBAR",
                }

            fts_project("imgui")


        -----------------------------------
        project "imgui"

            kind "StaticLib"
            language "C++"
            location (path.join(SLN_DIR, "projects"))
            flags { "NoEditAndContinue" }

            files { 
                path.join(ROOT_DIR, "code/thirdparty/imgui/**.h"),
                path.join(ROOT_DIR, "code/thirdparty/imgui/**.cpp"),
            }

            includedirs { 
                path.join(ROOT_DIR, "code/thirdparty") 
            }

            fts_project("imgui")
