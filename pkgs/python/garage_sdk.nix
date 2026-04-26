# toolz.nix
{
  buildPythonPackage,
  fetchgit,
  setuptools,
  wheel,
  urllib3,
  python-dateutil,
  pydantic,
  typing-extensions,
}:
buildPythonPackage
{
  pname = "garage_admin_sdk";
  version = "2.3.0";

  src = fetchgit {
    url = "https://git.deuxfleurs.fr/garage-sdk/garage-admin-sdk-python";
    branchName = "main-v2";
    rev = "709b9c1317e68b9f4ea5025ef8fa9df0d2ce899c";
    hash = "sha256-JyksxbAKzBdqXEOYBgeoBBQdxtHnegQM+fLulFKeG+s=";
  };

  dependencies = [
    urllib3
    python-dateutil
    pydantic
    typing-extensions
  ];

  # do not run tests
  doCheck = false;

  # specific to buildPythonPackage, see its reference
  pyproject = true;

  build-system = [
    setuptools
    wheel
  ];
}
