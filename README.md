# A Corpus Study of Rock Music

__The unofficial data repository of [A Corpus Study of Rock Music](http://rockcorpus.midside.com/index.html)__

This is a copy of the Corpus v2.1 created by Trevor de Clercq and David Temperley translated to JSON format. The aim of this project is make more accessible the data to programmers.

## Corpus

Currently the `corpus` folder contains the following JSON files:

- `corpus/files.json`: Song file names index by song titles
- `corpus/songs.json`: A songs indexed by song titles with song properties
- `corpus/stats.json`: Statistics (key frequency, ...)

## Build the corpus in JSON

Clone this repo and assuming you have node and npm installed type: `npm i && npm start`

## Resources

- [Home page](http://rockcorpus.midside.com/index.html)
- [2013 Paper](http://www.midside.com/publications/temperley_declercq_2013.pdf)
- [2011 Paper](http://rockcorpus.midside.com/2011_paper/declercq_temperley_2011.pdf)

## LICENSES

The Corpus data was created and mantained by Trevor de Clercq (trevor.declercq@gmail.com) and David Temperley (dtemperley@esm.rochester.edu) and has a CC-4.0-by License. All documents inside `source` folder are copied without modification from there.

The rest of the code has MIT License.
