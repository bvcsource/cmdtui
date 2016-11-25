#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let conf_coverage =
  Conf.key ~env:"BISECT_COVERAGE" "coverage" Conf.bool ~absent:false

let conf_lambda_term = Conf.with_pkg "lambda-term"
let conf_logs = Conf.with_pkg "logs"
let conf_cmdliner = Conf.with_pkg "cmdliner"

let () =
  let cmd c os files =
    let coverage = Cmd.(on (Conf.value c conf_coverage)
                          (v "-tag" % "package(bisect_ppx)")) in
    OS.Cmd.run
      Cmd.(Pkg.build_cmd c os %% coverage % "-j" % "0" %% of_list files) in
  let build = Pkg.build ~cmd () in
  let lint_deps_excluding = Some ["bisect_ppx"] in
  let opams = [Pkg.opam_file ~lint_deps_excluding "opam"] in

  let uri =
    match OS.File.read "_build/release.uri" with
    | Ok uri -> Some uri
    | Error _ -> None in
  let distrib = Pkg.distrib ?uri () in
  Pkg.describe "cmdtui" ~distrib ~build ~opams @@ fun c ->
  let lambda_term = Conf.(value c conf_lambda_term &&
                          value c conf_logs &&
                          value c conf_cmdliner) in
  Ok [ Pkg.mllib "src/cmdtui.mllib";
       Pkg.mllib ~cond:lambda_term "src/cmdtui_lambda_term.mllib";
       Pkg.doc "test/example.ml";
       Pkg.test ~cond:lambda_term ~run:false "test/example";
       Pkg.test ~cond:lambda_term "test/test"
     ]
