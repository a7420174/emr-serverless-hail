import sys
import argparse



def get_parser():
    parser = argparse.ArgumentParser(description='Hail Prep')
    parser.add_argument('-a', '--archives', type=str, required=True)
    parser.add_argument('-o', '--output', type=str, required=True)
    parser.add_argument('-t', '--tmp_dir', type=str, default='/tmp')
    return parser

def add_venv_to_path(archive_name):
    print(f"Adding {archive_name} to sys.path")
    sys.path.append(f"{archive_name}/lib/python3.11/site-packages")


def hail_process(args):
    import hail as hl
    
    hl.init(
        default_reference = 'GRCh38',
        tmp_dir = args.tmp_dir,
    )
    
    mt = hl.balding_nichols_model(n_populations=10,
                                n_samples=500,
                                n_variants=1_000_000,
                                n_partitions=300)
    mt = mt.annotate_cols(drinks_coffee = hl.rand_bool(0.33))
    gwas = hl.linear_regression_rows(y=mt.drinks_coffee,
                                    x=mt.GT.n_alt_alleles(),
                                    covariates=[1.0])
    gwas.write(args.output, overwrite=True)


def main():
    parser = get_parser()
    args = parser.parse_args()

    archive_name = args.archives
    add_venv_to_path(archive_name)
    hail_process(args)


if __name__ == "__main__":
    main()