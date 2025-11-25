#import "@preview/tidy:0.4.3"
#import "../lib.typ" as energetium
#import "template.typ": *

#let package = toml("../typst.toml").package
#show "energetium:0.0.0": "energetium:" + package.version
#show regex("<https://github.com/.*>"): it=> {
  linebreak()
  link(it.text.slice(1, it.text.len()-1))[#it.text.slice(1, it.text.len()-1)]
}

#show: project.with(
  title: package.name,
  subtitle: package.description,
  authors: package.authors,
  date: datetime.today().display("[month repr:long] [day], [year]"),
  version: package.version,
  url: package.repository
)

#let docs = tidy.parse-module(read("../lib.typ"), name: "Energetium",scope: (energetium:energetium), preamble: "#import energetium: *\n")

 #tidy.show-module(docs, show-outline: false)