using Conda
using Revise

# NOTE: when using and convert_md, pass `isinternal=true`
# to avoid clobbering global vars

# These must be set before initializing Franklin
py_v = chomp(String(read(`$(joinpath(Conda.BINDIR, "python")) -c "import sys; print(str(sys.version_info.major) + '.' + str(sys.version_info.minor))"`)))
ENV["PYTHON3"] = joinpath(Conda.BINDIR, "python")
ENV["PIP3"] = joinpath(Conda.BINDIR, "pip")
ENV["PYTHONPATH"] = "$(Conda.LIBDIR)/python$(py_v)"

using Franklin; const fr = Franklin;

using LDJ: ldjfranklin; ldjfranklin(); using LDJ.LDJFranklin
using Translator: franklinlangs; franklinlangs(); using Translator.FranklinLangs
using FranklinContent; FranklinContent.franklincontent_hfuncs()

# using Gumbo: HTMLElement, hasattr, setattr!, getattr
# using LDJ.LDJFranklin

