#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT=$(dirname ${BASH_SOURCE})/..

# # Reset the root BUILD file
# cat ${ROOT}/BUILD.bazel.tpl > ${ROOT}/BUILD.bazel

expose_package () {
	local out_path=$1
	local package=$2
	local old_links=$(eval echo \$$3)
	local generated_files=$(eval echo \$$4)

	# Compute the relative_path from this package to the bazel-bin
	local count_paths="$(echo -n "${package}" | tr '/' '\n' | wc -l)"
	local relative_path=""
	for i in $(seq 0 ${count_paths}); do
		relative_path="../${relative_path}"
	done

	# Delete all old links
	for f in ${old_links}; do
		if [[ -f "${f}" ]]; then
			echo "Deleting old link: ${f}"
			rm ${f}
		fi
	done

	# Link to the generated files and add them to excluding list in the root BUILD file
	local found=0
	for f in ${generated_files}; do
		if [[ -f "${f}" ]]; then
			found=1
			local base=${f##*/}
			echo "Adding a new link: ${package}/${base}"
			cp "$PWD/${f}" "${package}/"
		fi
	done
	if [[ "${found}" == "0" ]]; then
		echo "Error: No generated file was found inside ${out_path} for the package ${package}"
		exit 1
	fi
}


####################
# For proto go files
####################

# Build proto go files for this package
targets='
    //proto:service_python_grpc
'

for label in ${targets}; do
	bazel build "${label}"
done

# Link to the generated files and add them to excluding list in the root BUILD file
for label in ${targets}; do
	package="${label%%:*}"
	package="${package##//}"
	target="${label##*:}"
	[[ -d "${package}" ]] || continue

	# Compute the path where Bazel puts the files
	out_path="bazel-bin/${package}"

	old_links=$(eval echo ${package}/*{_pb2.py,_pb2_grpc.py})
	generated_files=$(eval echo ${out_path}/*{_pb2.py,_pb2_grpc.py})
	expose_package ${out_path} ${package} old_links generated_files
done