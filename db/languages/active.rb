@languages ||= []
@languages +=
  [
    # {
    #   id: 50,
    #   name: "C (GCC 12.2.0)",
    #   monaco_name: "cpp",
    #   is_archived: false,
    #   source_file: "main.c",
    #   compile_cmd: "gcc %s main.c",
    #   run_cmd: "./a.out"
    # },
    {
      id: 54,
      name: "C++",
      major: 12,
      minor: 2,
      patch: 0,
      monaco_name: "cpp",
      is_archived: false,
      source_file: "main.cpp",
      compile_cmd: "g++ %s main.cpp -Werror=return-type",
      run_cmd: "./a.out"
    },
    {
      id: 63,
      name: "JavaScript",
      major: 22,
      minor: 14,
      patch: 0,
      monaco_name: "javascript",
      is_archived: false,
      source_file: "script.js",
      run_cmd: "node script.js"
    },
    {
      id: 68,
      name: "PHP",
      major: 8,
      minor: 4,
      patch: 5,
      monaco_name: "php",
      is_archived: false,
      source_file: "script.php",
      run_cmd: "php script.php"
    },
    {
      id: 71,
      name: "Python",
      major: 3,
      minor: 13,
      patch: 2,
      monaco_name: "python",
      is_archived: false,
      source_file: "script.py",
      run_cmd: "python3 script.py"
    }
  ]
