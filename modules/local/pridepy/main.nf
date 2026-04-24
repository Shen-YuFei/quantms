process PRIDEPY_DOWNLOAD {
    tag "${meta.id}"
    label 'process_low'
    label 'process_long'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pridepy:0.0.14--pyhdfd78af_0' :
        'quay.io/biocontainers/pridepy:0.0.14--pyhdfd78af_0' }"

    input:
    val(meta)

    output:
    path "output/",      emit: download_dir, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p output
    pridepy ${args}

    pridepy_version=\$(pip show pridepy 2>/dev/null | grep Version | cut -d' ' -f2)
    printf '"%s":\\n    pridepy: %s\\n' "${task.process}" "\$pridepy_version" > versions.yml
    """

    stub:
    """
    mkdir -p output
    touch output/${meta.id}.placeholder

    printf '"%s":\\n    pridepy: %s\\n' "${task.process}" "0.0.14" > versions.yml
    """
}
