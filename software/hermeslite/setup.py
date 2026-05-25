from setuptools import setup, find_packages

setup(
    name="hermeslite",
    version="1.0.0",
    description="Python module for Hermes-Lite 2.0 command and control",
    packages=find_packages(),
    install_requires=[
        "netifaces",
    ],
    python_requires=">=3.6",
)
