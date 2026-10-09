process PREPARE_LFQ_GROUPS {
    tag "${sdrf.baseName}"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quantms-utils:0.0.31--pyhdfd78af_0' :
        'biocontainers/quantms-utils:0.0.31--pyhdfd78af_0' }"

    input:
    path(sdrf)
    path(expdes)
    val(columns)

    output:
    path 'lfq_groups.tsv', emit: manifest
    path 'lfq_group_*.tsv', emit: designs
    path 'versions.yml', emit: versions

    script:
    def columnArgs = columns.collect { "--column '${it.replace("'", "'\"'\"'")}'" }.join(' ')
    """
    quantmsutilsc splitlfqgroups \\
        --sdrf '${sdrf}' \\
        --design '${expdes}' \\
        ${columnArgs}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quantms-utils: \$(pip show quantms-utils | grep "Version" | awk -F ': ' '{print \$2}')
    END_VERSIONS
    """
}

// Keep the run/design/SDRF association in one tuple even when groups finish out of order.
def group_lfq_inputs(ch_runs, ch_manifest) {
    def ch_group_runs = ch_manifest
        .map { manifest -> tuple(manifest.parent, manifest) }
        .splitCsv(elem: 1, header: true, sep: '\t')
        .map { directory, row ->
            tuple(row.run_id, row.group_id, directory.resolve(row.design_file), directory.resolve(row.sdrf_file))
        }
    return ch_runs
        .map { meta, mzml, ids -> tuple(mzml.baseName, mzml, ids) }
        .join(ch_group_runs, failOnDuplicate: true, failOnMismatch: true)
        .map { run, mzml, ids, groupId, design, groupSdrf -> tuple(groupId, design, groupSdrf, mzml, ids) }
        .groupTuple(by: [0, 1, 2])
        .map { groupId, design, groupSdrf, mzmls, ids -> tuple(mzmls, ids, design, groupSdrf) }
}
