from pathlib import Path

project_dir = Path.cwd().resolve()

data_dir = (project_dir / "data").resolve()
plots_dir = (project_dir / "plots").resolve()
images_dir = (project_dir / "images").resolve()
scripts_dir = (project_dir / "scripts").resolve()

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
# Your startup customizations goes below here
# ----------------------------------------------------------


# ----------------------------------------------------------
# End of startup customizations
# ----------------------------------------------------------
print("startup configurations loaded successfully.")
