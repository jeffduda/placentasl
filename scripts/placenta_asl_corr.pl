#!/usr/bin/perl -w

##
## sample usage:
##
##


# use module
use Data::Dumper;
use Cwd 'realpath';
use Cwd;
use File::Spec;
use File::Find;
use File::Basename;
use File::Path;
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);

my $start = time;

my $ANTSPATH = "/data/picsl/jtduda/bin/ants/";

my ($M0, $ASL, $ODIR, $ONAME) = @ARGV;
my @filetypes = (".nii.gz");

#my $TDIR = tempdir( CLEANUP => 1 );
$TDIR=$ODIR;

print("$M0 $ASL\n");

#=begin GHOSTCODE

make_path( $ODIR );
mkdir "${TDIR}/M0";
mkdir "${TDIR}/ASL";
mkdir "${TDIR}/ASL/split0";
mkdir "${TDIR}/ASL/split1";

system("${ANTSPATH}ImageMath 4 ${TDIR}/M0/M0_time_.nii.gz TimeSeriesDisassemble $M0");
my @M0Times = glob("${TDIR}/M0/M0_time_????.nii.gz");
system("${ANTSPATH}AverageImages 3 ${TDIR}/M0/M0_mean.nii.gz 0 ${TDIR}/M0/M0_time_*.nii.gz");
print("\n");


# Affine M0 template steps
for (my $i=0; $i < 3; $i++ ) {
  system("${ANTSPATH}ImageMath 3 ${TDIR}/M0/M0_mean_pad.nii.gz PadImage ${TDIR}/M0/M0_mean.nii.gz 5");

  foreach (@M0Times) {
    my ($name,$path,$suffix) = fileparse($_,@filetypes);
    my @nameparts = split("_", $name);
    my $num = $nameparts[2];
    print("$num : $i \n");

    my $oname = "[ ${TDIR}/M0/M0_time_${num}_affine_${i}_, ${TDIR}/M0/M0_time_${num}_affine_${i}_corr.nii.gz ]";

    system("${ANTSPATH}antsRegistration -d 3 -m MI[ ${TDIR}/M0/M0_mean_pad.nii.gz, $_, 1, 32, Regular, 0.5 ] -s 0 -f 1 -c [100,1e-7] -t Affine[0.2] --restrict-deformation 1x1x0x1x1x0x0x0x0x1x1x0 -o ${oname} -v 1");

    system("${ANTSPATH}ImageMath 3 ${TDIR}/M0/M0_time_${num}_affine_${i}_corr.nii.gz PadImage ${TDIR}/M0/M0_time_${num}_affine_${i}_corr.nii.gz -5");
  }

  system("${ANTSPATH}AverageImages 3 ${TDIR}/M0/M0_mean.nii.gz 0 ${TDIR}/M0/M0_time_*_affine_${i}.nii.gz");

  print("\n");
  system("cp ${TDIR}/M0/M0_mean.nii.gz ${TDIR}/M0/M0_mean_affine_${i}.nii.gz");

}


system("cp ${TDIR}/M0/M0_mean.nii.gz ${ODIR}/${ONAME}M0_affine_mean.nii.gz");
system("${ANTSPATH}ImageMath 3 ${TDIR}/M0/M0_mean_pad.nii.gz PadImage ${TDIR}/M0/M0_mean.nii.gz 5");

# Non-linear M0 template steps
foreach (@M0Times) {
    my ($name,$path,$suffix) = fileparse($_,@filetypes);
    my @nameparts = split("_", $name);
    my $num = $nameparts[2];
    print("$num\n");

    my $oname = "[ ${TDIR}/M0/M0_time_${num}_def_,  ${TDIR}/M0/M0_time_${num}_def_corr.nii.gz ]";

    system("${ANTSPATH}antsRegistration -d 3 -m MI[ ${TDIR}/M0/M0_mean_pad.nii.gz, $_, 1, 32, Regular, 0.5 ] -s 0 -f 1 -c [100,1e-7] -t Affine[0.2] --restrict-deformation 1x1x0x1x1x0x0x0x0x1x1x0 -m CC[ ${TDIR}/M0/M0_mean_pad.nii.gz, $_, 1, 4, Regular, 0.5 ] -s 0 -f 1 -c [20,1e-7] -t SyN[0.2] --restrict-deformation 1x1x0 -o ${oname} -v 1");

    system("${ANTSPATH}ImageMath 3 ${TDIR}/M0/M0_time_${num}_def_corr.nii.gz PadImage ${TDIR}/M0/M0_time_${num}_def_corr.nii.gz -5");

}

system("${ANTSPATH}ImageMath 4 ${ODIR}/${ONAME}M0_corr.nii.gz TimeSeriesAssemble 1 0 ${TDIR}/M0/M0_*_def_corr.nii.gz");
system("${ANTSPATH}AverageImages 3 ${TDIR}/M0/M0_mean.nii.gz 0 ${TDIR}/M0/M0_*_def_corr.nii.gz");
system("${ANTSPATH}ImageMath 3 ${TDIR}/M0/M0_mean_pad.nii.gz PadImage ${TDIR}/M0/M0_mean.nii.gz 5");
print( "\n" );
system("cp ${TDIR}/M0/M0_mean.nii.gz ${ODIR}/${ONAME}M0_def_mean.nii.gz");


system("${ANTSPATH}ImageMath 4 ${TDIR}/ASL/ASL_time_.nii.gz TimeSeriesDisassemble $ASL");
my @ASLTimes = glob("${TDIR}/ASL/ASL_time_????.nii.gz");
my $count = 0;
foreach (@ASLTimes) {
    my ($name,$path,$suffix) = fileparse($_,@filetypes);
    my @nameparts = split("_", $name);
    my $num = $nameparts[2];
    print("$num\n");

    my $oname = "[ ${TDIR}/ASL/ASL_time_${num}_def_,  ${TDIR}/ASL/ASL_time_${num}_def_corr.nii.gz ]";

    system("${ANTSPATH}antsRegistration -d 3 -m MI[ ${TDIR}/M0/M0_mean_pad.nii.gz, $_, 1, 32, Regular, 0.5 ] -s 0 -f 1 -c [200,1e-7] -t Affine[0.2] --restrict-deformation 1x1x0x1x1x0x0x0x0x1x1x0 -m CC[ ${TDIR}/M0/M0_mean_pad.nii.gz, $_, 1, 4, Regular, 0.5 ] -s 0 -f 1 -c [20,1e-7] -t SyN[0.2] --restrict-deformation 1x1x0 -o ${oname} -v 1");

    system("${ANTSPATH}ImageMath 3 ${TDIR}/ASL/ASL_time_${num}_def_corr.nii.gz PadImage ${TDIR}/ASL/ASL_time_${num}_def_corr.nii.gz -5");

    my $is_even = $count % 2 == 0;
    if ( $is_even ) {
      system("cp ${TDIR}/ASL/ASL_time_${num}* ${TDIR}/ASL/split0/");
    } else {
      system("cp ${TDIR}/ASL/ASL_time_${num}* ${TDIR}/ASL/split1/");
    }

    $count = $count + 1;


# Split tag & control for final correction stage
system("cp ${TDIR}/M0/M0_mean.nii.gz ${ODIR}/${ONAME}M0_corr_mean.nii.gz");
system("${ANTSPATH}ImageMath 4 ${ODIR}/${ONAME}ASL_corr_global.nii.gz TimeSeriesAssemble 1 0 ${TDIR}/ASL/ASL_*_def_corr.nii.gz");

}

#=end GHOSTCODE
#=cut

system("${ANTSPATH}AverageImages 3 ${TDIR}/ASL/split0/ASL_split0_mean.nii.gz 0 ${TDIR}/ASL/split0/ASL_*_def_corr.nii.gz");
system("${ANTSPATH}AverageImages 3 ${TDIR}/ASL/split1/ASL_split1_mean.nii.gz 0 ${TDIR}/ASL/split1/ASL_*_def_corr.nii.gz");

system("${ANTSPATH}ImageMath 3 ${TDIR}/ASL/split0/ASL_split0_mean_pad.nii.gz PadImage ${TDIR}/ASL/split0/ASL_split0_mean.nii.gz 5");
system("${ANTSPATH}ImageMath 3 ${TDIR}/ASL/split1/ASL_split1_mean_pad.nii.gz PadImage ${TDIR}/ASL/split1/ASL_split1_mean.nii.gz 5");

@ASLTimes = glob("${TDIR}/ASL/split0/ASL_time_????.nii.gz");
foreach (@ASLTimes) {
    my ($name,$path,$suffix) = fileparse($_,@filetypes);
    my @nameparts = split("_", $name);
    my $num = $nameparts[2];
    print("$num\n");

    my $oname = "[ ${TDIR}/ASL/split0/ASL_time_${num}_fulldef_,  ${TDIR}/ASL/split0/ASL_time_${num}_fulldef_corr.nii.gz ]";

    system("${ANTSPATH}antsRegistration -d 3 -m CC[ ${TDIR}/ASL/split0/ASL_split0_mean_pad.nii.gz, $_, 1, 7, Regular, 0.5 ] -s 0 -f 1 -c [50,1e-7] -t SyN[0.4,3,0] -o $oname -r ${TDIR}/ASL/split0/ASL_time_${num}_def_1Warp.nii.gz -r ${TDIR}/ASL/split0/ASL_time_${num}_def_0GenericAffine.mat --restrict-deformation 1x1x0.2  -v 1");

    system("${ANTSPATH}ImageMath 3 ${TDIR}/ASL/split0/ASL_time_${num}_fulldef_corr.nii.gz PadImage ${TDIR}/ASL/split0/ASL_time_${num}_fulldef_corr.nii.gz -5");
}

@ASLTimes = glob("${TDIR}/ASL/split1/ASL_time_????.nii.gz");
foreach (@ASLTimes) {
    my ($name,$path,$suffix) = fileparse($_,@filetypes);
    my @nameparts = split("_", $name);
    my $num = $nameparts[2];
    print("$num\n");

    my $oname = "[ ${TDIR}/ASL/split1/ASL_time_${num}_fulldef_,  ${TDIR}/ASL/split1/ASL_time_${num}_fulldef_corr.nii.gz ]";

    system("${ANTSPATH}antsRegistration -d 3 -m CC[ ${TDIR}/ASL/split1/ASL_split1_mean_pad.nii.gz, $_, 1, 7, Regular, 0.5 ] -s 0 -f 1 -c [50,1e-7] -t SyN[0.4,3,0] -o $oname -r ${TDIR}/ASL/split1/ASL_time_${num}_def_1Warp.nii.gz -r ${TDIR}/ASL/split1/ASL_time_${num}_def_0GenericAffine.mat --restrict-deformation 1x1x0.2  -v 1");

    system("${ANTSPATH}ImageMath 3 ${TDIR}/ASL/split1/ASL_time_${num}_fulldef_corr.nii.gz PadImage ${TDIR}/ASL/split1/ASL_time_${num}_fulldef_corr.nii.gz -5");
}

system("${ANTSPATH}ImageMath 4 ${ODIR}/${ONAME}ASL_corr.nii.gz TimeSeriesAssemble 1 0 ${TDIR}/ASL/split?/ASL_*_fulldef_corr.nii.gz");




my $end = time;
my $diff = $end - $start;
print "\n Total Run Time: $diff seconds\n";
