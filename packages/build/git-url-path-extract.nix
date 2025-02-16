{
  writers,
}:

let
  gist = builtins.fetchGit {
    url = "https://gist.github.com/alexpovel/df0f4922b973b820f15e357ea951abdc.git";
    rev = "ea42659e47dc85bde5575a6906fb219c5611e9c5";
  };
in
writers.writePython3Bin "git-url-extract-path" {
  flakeIgnore = [
    "E501" # line too long
  ];
} (builtins.readFile "${gist}/git-url-path-extract.py")
