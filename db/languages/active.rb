@languages ||= []
@languages +=
  [
    # {
    #   id: 50,
    #   name: "C (GCC 14.1.0)",
    #   monaco_name: "cpp",
    #   is_archived: false,
    #   source_file: "main.c",
    #   compile_cmd: "/usr/local/gcc-14.1.0/bin/gcc %s main.c",
    #   run_cmd: "./a.out"
    # },
    {
      id: 54,
      name: "C++ (GCC 14.1.0)",
      monaco_name: "cpp",
      is_archived: false,
      source_file: "main.cpp",
      compile_cmd: "/usr/local/gcc-14.1.0/bin/g++ %s main.cpp -Werror=return-type",
      run_cmd: "LD_LIBRARY_PATH=/usr/local/gcc-14.1.0/lib64 ./a.out"
    },
    {
      id: 63,
      name: "JavaScript (Node.js 20.15.1)",
      monaco_name: "javascript",
      is_archived: false,
      source_file: "script.js",
      run_cmd: "/usr/local/node-20.15.1/bin/node script.js"
    },
    {
      id: 68,
      name: "PHP (8.3.9)",
      monaco_name: "php",
      is_archived: false,
      source_file: "script.php",
      run_cmd: "/usr/local/php-8.3.9/bin/php script.php"
    },
    {
      id: 71,
      name: "Python (3.12.4)",
      monaco_name: "python",
      is_archived: false,
      source_file: "script.py",
      run_cmd: "/usr/local/python-3.12.4/bin/python3 script.py"
    }
  ]
