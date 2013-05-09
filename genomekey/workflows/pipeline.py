from genomekey.tools import gatk, picard, bwa, misc, bamUtil,pipes
from cosmos.contrib.ezflow.dag import add_,map_,reduce_,split_,reduce_split_,sequence_,apply_
from genomekey.workflows.annotate import massive_annotation
from genomekey.wga_settings import wga_settings

def Pipeline():
    # Split Tags
    intervals = ('interval',range(1,23) + ['X', 'Y']) if not wga_settings['test'] else ('interval',[20])
    glm = ('glm', ['SNP', 'INDEL'])

    align_to_reference = sequence_(
        apply_(
            reduce_(['sample_name', 'library'], misc.FastqStats),
            reduce_(['sample_name', 'library', 'platform', 'platform_unit', 'chunk'],pipes.AlignAndClean)
        ),
    )

    preprocess_alignment = sequence_(
        reduce_(['sample_name'], picard.MarkDuplicates),
        apply_(
            map_(picard.CollectMultipleMetrics),
            split_([intervals],gatk.RealignerTargetCreator)
        ),
        map_(gatk.IR),
        map_(gatk.BQSR),
        apply_(
            reduce_(['sample_name'], gatk.BQSRGatherer),
            map_(gatk.ApplyBQSR) #TODO I add BQSRGatherer as a parent with a hack inside ApplyBQSR.cmd
        )
    )

    call_variants = sequence_(
        apply_(
            reduce_(['interval'],gatk.HaplotypeCaller,tag={'vcf':'HaplotypeCaller'}),
            reduce_split_(['interval'],[glm], gatk.UnifiedGenotyper,tag={'vcf':'UnifiedGenotyper'}),
            combine=True
        ),
        reduce_(['vcf'], gatk.CombineVariants, 'Combine Into Raw VCFs'),
        split_([glm],gatk.VQSR),
        map_(gatk.Apply_VQSR),
        reduce_(['vcf'], gatk.CombineVariants, "Combine into Master VCFs")
    )

    if wga_settings['capture']:
        return sequence_(
            align_to_reference,
            preprocess_alignment,
            #reduce_split_([],[intervals],gatk.ReduceReads),
            call_variants,
            massive_annotation
        )
    else:
        return sequence_(
            align_to_reference,
            preprocess_alignment,
            reduce_split_([],[intervals],gatk.ReduceReads),
            call_variants,
            massive_annotation
        )