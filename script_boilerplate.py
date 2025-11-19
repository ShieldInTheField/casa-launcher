from pathlib import Path

scripts_dir = Path(__file__).parent.resolve()
project_dir = (scripts_dir / "..").resolve()

data_dir = (project_dir / "data").resolve()
plots_dir = (project_dir / "plots").resolve()
images_dir = (project_dir / "images").resolve()

for d in (data_dir, plots_dir, images_dir, scripts_dir):
    d.mkdir(parents=True, exist_ok=True)


def data(name):
    return str(data_dir / name)


def plots(name):
    return str(plots_dir / name)


def images(name):
    return str(images_dir / name)


def scripts(name):
    return str(scripts_dir / name)


# ----------------------------------------------------------
# Your CASA code goes below here
# ----------------------------------------------------------
