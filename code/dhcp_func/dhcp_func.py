#!/usr/bin/env python
import logging
import os
from tempfile import TemporaryDirectory
import subprocess
import sys
sys.path.append('/home/johann.drayne/.local/lib/python3.7/site-packages')
sys.path.append('/home/johann.drayne/.local/lib/python3.8/site-packages')

from fsl.utils.filetree import FileTree


from dhcp.func import mcdc, ica, importdata, registration as reg, denoise as fix
from dhcp.util import util, fslpy as fsl
from dhcp.util.enums import PhaseEncodeDirection, SegType, FieldmapType, PhaseUnits
from dhcp.util.io import Path
from dhcp.util.acqparam import _get_axis as get_axis

import numpy as np

############
# PARAMETERS
############

# Set the parameters for the operation of the pipeline.
# These parameters will need to ba adjusted according to your specific requirements, especially the paths.

INPUT_PATH = './'
LOCAL_BIN = './bin'
highDir='/home/johann.drayne/'
dataDir='/mnt/WeberLab/Projects/NeonateSucrose/SickKids/'

# environment variables


os.environ['FSL_FIX_MATLAB_MODE'] = '1'
os.environ['MATLAB_BIN'] = '/usr/local/bin/matlab'
os.environ['DHCP_FIX_PATH'] = '/usr/local/fix'
os.environ['DHCP_ANTS_PATH'] = '/usr/local/ANTs/bin'
os.environ['DHCP_C3D_PATH'] = '/mnt/WeberLab/Projects/NeonateSucrose/SickKids/bin'
os.environ['DHCP_EDDY_PATH'] = '/usr/local/fsl/bin'


# subject info
subid = str(sys.argv[2])
sub_age = str(sys.argv[1])
#subid = 'MS040064'
sesid = 'session1'
#sub_age = 'v02'

#change this line when runnning script in local vs. /mnt
inputDir=f'{highDir}dhcp_func/dhcp_func_input/{sub_age}/{subid}/'

#runs the file that will create all the inputs
file = f'{highDir}dhcp_func/input_dhcp_func.sh'

subprocess.run(["bash", f"{file}", f"{subid}", f"{sub_age}"], capture_output=True)

#looks at info file, which contains parsed info of echo spacing and age
infofile = f"{highDir}dhcp_func/dhcp_func_input/{sub_age}/{subid}/info.txt"
f = open(f"{infofile}", "rt")
birth_ga, scan_pma, echo = f.read().split()

scan_pma = float(scan_pma)
birth_ga = float(birth_ga)


# output workdir
workdir = Path(f'{highDir}dhcp_func/dhcp_func_output_fullrun/{sub_age}/')

# imaging parameters
AP = PhaseEncodeDirection.AP
PA = PhaseEncodeDirection.PA
RL = PhaseEncodeDirection.RL


sbref_echospacing = float(echo)
sbref_pedir = AP

func_echospacing = float(echo)
func_pedir = AP


# pipeline parameters

do_bbr_fmap = True  # do not use BBR for fmap registration to structural
# in dHCP, the dual-echo-derived fmap_mag does not have sufficient tissue contrast to support BBR
# if your dual-echo-derived fmap_mag does have good tissue contrast then it is recommended to use BBR

do_bbr_sbref = True  # use BBR for sbref registration to structural
use_mcflirt = False
do_dc = True  # do distortion correction of func and sbref
do_s2v = True  # do slice-to-volume motion correction
do_mbs = True  # do motion-by-susceptibility distortion correction

temporal_fwhm = 150.0  # high-pass filter cut-off (secs)
ica_dim = 150  # cap on single-subject ICA dimensionality

############
# LOGGING & DEFAULT OUTPUT FILENAMES
############

# setup logging
logging.basicConfig(
    format='[%(asctime)s - %(name)s.%(funcName)s ] %(levelname)s : %(message)s',
    level=logging.INFO
)

# setup defaults
defaults = FileTree.read(util.get_resource('dhcp-defaults.tree'), partial_fill=False).update(
    subid=subid,
    sesid=sesid,
    workdir=workdir,
)

############
# IMPORT
############

subdir = f'sub-{subid}/ses-{sesid}'

importdata.DEFAULTS = defaults

importdata.import_info(
    subid=subid,
    sesid=sesid,
    scan_pma=scan_pma,
    birth_ga=birth_ga,
)
## changed func_slorder=util.get_resource('default_func.slorder')
importdata.import_func(
    func=f'{inputDir}func.nii.gz',
    func_slorder=f'{inputDir}slicetime.txt',
    func_pedir=func_pedir,
    func_echospacing=func_echospacing,
    sbref=f'{inputDir}sbref.nii.gz',
    sbref_pedir=sbref_pedir,
    sbref_echospacing=sbref_echospacing,
)

importdata.import_struct(
    T2w=f'{inputDir}t2.nii.gz',
    T1w=f'{inputDir}t1.nii.gz',
    brainmask=f'{inputDir}mask.nii.gz',
    dseg=f'{inputDir}dseg.nii.gz',
)


with TemporaryDirectory(dir=workdir) as tmp:
    # select first volume of dual-echo-time-derived (Dual-TE gradient-echo) fmap/magnitude
    # in dHCP there are two volumes for different filtering parameters
    # this would not typically be required for a standard single-volume fieldmap

#    fsl.fslroi(
#        input=f'{inputDir}fmap_rads.nii.gz',
#        output=f'{tmp}/fmap.nii.gz',
#        tmin=0, tsize=1
#    )
#
#    fsl.fslroi(
#        input=f'{inputDir}mag.nii.gz',
#        output=f'{tmp}/fmap_mag.nii.gz',
#        tmin=0, tsize=1
#    )
#
#    # import the fieldmap and magnitude image
#
#    importdata.import_fieldmap(
#        fieldmap=f'{tmp}/fmap.nii.gz',
#        fieldmap_magnitude=f'{tmp}/fmap_mag.nii.gz',
#        fieldmap_units=PhaseUnits.hz,
#        fieldmap_type=FieldmapType.dual_echo_time_derived,
#    )
#


#         fieldmap_brainmask=f'{inputDir}fmap_brainmask.nii.gz',


    importdata.import_fieldmap(
        fieldmap=f'{inputDir}fmap_rads.nii.gz',
        fieldmap_magnitude=f'{inputDir}mag.nii.gz',
        fieldmap_units=PhaseUnits.rads,
        fieldmap_type=FieldmapType.dual_echo_time_derived,
    )

###########
# REG A
###########
print(" -----\n", "-----\n", "-----\n", "REG A started\n", "-----\n", "-----\n", "-----\n")
# fmap -> struct

reg.DEFAULTS = defaults.update(src_space='fmap', ref_space='struct')

reg.fmap_to_struct(
    fmap=defaults.get('fmap'),
    fmap_magnitude=defaults.get('fmap_magnitude'),
    fmap_brainmask=defaults.get('fmap_brainmask'),
    struct=defaults.get('T2w'),
    struct_brainmask=defaults.get('T2w_brainmask'),
    struct_boundarymask=defaults.get('T2w_wmmask'),
    do_bbr=do_bbr_fmap
)

# func -> sbref (distorted)

reg.DEFAULTS = defaults.update(src_space='func', ref_space='sbref')

reg.func_to_sbref(
    func=defaults.get('func0'),
    func_brainmask=defaults.get('func_brainmask'),
    sbref=defaults.get('sbref'),
    sbref_brainmask=defaults.get('sbref_brainmask')
)

# sbref -> struct (with BBR and DC)

reg.DEFAULTS = defaults.update(src_space='sbref', ref_space='struct')

reg.sbref_to_struct(
    sbref=defaults.get('sbref'),
    sbref_brainmask=defaults.get('sbref_brainmask'),
    sbref_pedir=sbref_pedir,
    sbref_echospacing=sbref_echospacing,
    struct=defaults.get('T2w'),
    struct_brainmask=defaults.get('T2w_brainmask'),
    struct_boundarymask=defaults.get('T2w_wmmask'),
    fmap=defaults.get('fmap'),
    fmap_brainmask=defaults.get('fmap_brainmask'),
    fmap2struct_xfm=defaults.update(src_space='fmap', ref_space='struct').get('affine'),
    do_bbr=do_bbr_sbref,
    do_dc=do_dc,
)

# func (distorted) -> sbref -> struct (composite)

reg.DEFAULTS = defaults.update(src_space='func', ref_space='struct')

reg.func_to_struct_composite(
    func=defaults.get('func0'),
    struct=defaults.get('T2w'),
    func2sbref_affine=defaults.update(src_space='func', ref_space='sbref').get('affine'),
    sbref2struct_affine=defaults.update(src_space='sbref', ref_space='struct').get('affine'),
    sbref2struct_warp=defaults.update(src_space='sbref', ref_space='struct').get('warp'),
)

# fmap -> func (composite)

reg.DEFAULTS = defaults.update(src_space='fmap', ref_space='func')

reg.fmap_to_func_composite(
    fmap=defaults.get('fmap'),
    func=defaults.get('func0'),
    fmap2struct_affine=defaults.update(src_space='fmap', ref_space='struct').get('affine'),
    func2struct_invaffine=defaults.update(src_space='func', ref_space='struct').get('inv_affine'),
)


# transform fieldmap_brainmask to func space

fsl.applyxfm(
    src=defaults.get('fmap_brainmask'),
    ref=defaults.get('func0'),
    mat=defaults.update(src_space='fmap', ref_space='func').get('affine'),
    out=defaults.update(src_space='fmap', ref_space='func').get('resampled_brainmask'),
    interp='nearestneighbour'
)

print(" -----\n", "-----\n", "-----\n", "REG A completed\n", "-----\n", "-----\n", "-----\n")


############
# motion correction
############
print(" -----\n", "-----\n", "-----\n", "motion correction started\n", "-----\n", "-----\n", "-----\n")

defaults = defaults.update(dc='dc')
mcdc.DEFAULTS = defaults


fmap = defaults.update(src_space='fmap', ref_space='func').get('resampled_image')
fmap_brainmask = defaults.update(src_space='fmap', ref_space='func').get('resampled_brainmask')
unwarpdir = get_axis(defaults.get('func'), func_pedir.name)[0]


fsl.fugue(
    loadfmap=fmap,
    mask=fmap_brainmask,
    unmaskfmap=True,
    savefmap=fmap,
    unwarpdir=unwarpdir,
)

#    fmap=defaults.update(src_space='fmap', ref_space='func').get('resampled_image'),
# func_slorder chenged util.get_resource('default_func.slorder')
mcdc.mcdc(
    func=defaults.get('func'),
    func_brainmask=defaults.get('func_brainmask'),
    fmap=fmap,
    func_echospacing=func_echospacing,
    func_pedir=func_pedir,
    func_slorder=defaults.get('func_slorder'),
    do_dc=True,
    do_s2v=True,
    do_mbs=True,
    use_mcflirt=False,
)

print(" -----\n", "-----\n", "-----\n", "motion correction completed\n", "-----\n", "-----\n", "-----\n")


############
# REG B
############
print(" -----\n", "-----\n", "-----\n", "REG B started\n", "-----\n", "-----\n", "-----\n")
# func -> sbref (undistorted)

reg.DEFAULTS = defaults.update(src_space='func-mcdc', ref_space='sbref-dc')

reg.func_to_sbref(
    func=defaults.get('func_mcdc_mean'),
    func_brainmask=defaults.get('func_mcdc_brainmask'),
    sbref=defaults.update(src_space='sbref', ref_space='struct').get('dc_image'),
    sbref_brainmask=defaults.update(src_space='sbref', ref_space='struct').get('dc_brainmask')
)

# func (undistorted) -> sbref -> struct (composite)

reg.DEFAULTS = defaults.update(src_space='func-mcdc', ref_space='struct')

reg.func_to_struct_composite(
    func=defaults.get('func_mcdc_mean'),
    struct=defaults.get('T2w'),
    func2sbref_affine=defaults.update(src_space='func-mcdc', ref_space='sbref-dc').get('affine'),
    sbref2struct_affine=defaults.update(src_space='sbref', ref_space='struct').get('affine'),
    sbref2struct_warp=defaults.update(src_space='sbref', ref_space='struct').get('warp'),
)

print(" -----\n", "-----\n", "-----\n", "REG B completed\n", "-----\n", "-----\n", "-----\n")



############
# ICA
############

print(" -----\n", "-----\n", "-----\n", "ICA started\n", "-----\n", "-----\n", "-----\n")

ica.DEFAULTS = defaults

ica.ica(
    func=defaults.get('func_mcdc'),
    func_brainmask=defaults.get('func_mcdc_brainmask'),
    temporal_fwhm=temporal_fwhm,
    icadim=ica_dim,
)

util.update_sidecar(
    defaults.get('func_filt'),
    temporal_fwhm=temporal_fwhm,
)

print(" -----\n", "-----\n", "-----\n", "ICA completed\n", "-----\n", "-----\n", "-----\n")



############
# FIX
############
print(" -----\n", "-----\n", "-----\n", "FIX started\n", "-----\n", "-----\n", "-----\n")

fix.DEFAULTS = defaults

fix.fix_extract(
    func_filt=defaults.get('func_filt'),
    func_ref=defaults.get('func_mcdc_mean'),
    struct=defaults.get('T2w'),
    struct_brainmask=defaults.get('T2w_brainmask'),
    struct_dseg=defaults.get('T2w_dseg'),
    dseg_type=SegType.drawem,
    func2struct_mat=defaults.update(src_space='func-mcdc', ref_space='struct').get('affine'),
    mot_param=defaults.get('motparams'),
    icadir=defaults.get('icadir'),
    temporal_fwhm=temporal_fwhm,
)

fix.fix_classify(
    rdata=util.get_setting('dhcp_trained_fix', None),
    threshold=util.get_setting('dhcp_trained_fix_threshold', None),
)



fix.fix_apply(
    temporal_fwhm=temporal_fwhm,
)
print(" -----\n", "-----\n", "-----\n", "FIX completed\n", "-----\n", "-----\n", "-----\n")



############
# STANDARD
############
print(" -----\n", "-----\n", "-----\n", "Standard started\n", "-----\n", "-----\n", "-----\n")

scan_ga = util.json2dict(defaults.get('subject_info'))['scan_pma']
age = int(np.round(scan_ga))

atlas_tree = Path(util.get_setting('dhcp_volumetric_atlas_tree'))
#atlas_tree = Path('/home/johann.drayne/dhcpfmri/data/dhcp_volumetric_atlas_extended/atlas/atlas.tree')
atlas = FileTree.read(atlas_tree).update(path=atlas_tree.dirname)

# template (scan-age) -> struct

reg.DEFAULTS = defaults.update(src_space=f'template-{age}', ref_space='struct')

reg.template_to_struct(
    age=age,
    struct_brainmask=defaults.get('T2w_brainmask'),
    struct_T1w=defaults.get('T1w') if defaults.on_disk('T1w') else None,
    struct_T2w=defaults.get('T2w'),
    atlas=atlas,
)

# struct -> age-matched template -> standard template (composite)

standard_age = 40
reg.DEFAULTS = defaults.update(src_space='struct', ref_space='standard')

reg.struct_to_template_composite(
    struct=defaults.get('T2w'),
    struct2template_warp=defaults.update(src_space=f'template-{age}', ref_space='struct').get('inv_warp'),
    age=age,
    standard_age=standard_age,
    atlas=atlas,
)

# func (undistorted) -> struct -> age-matched template -> standard template (composite)

reg.DEFAULTS = defaults.update(src_space='func-mcdc', ref_space='standard')

reg.func_to_template_composite(
    func=defaults.get('func_mcdc_mean'),
    func2struct_affine=defaults.update(src_space='func-mcdc', ref_space='struct').get('affine'),
    struct2template_warp=defaults.update(src_space='struct', ref_space='standard').get('warp'),
    standard_age=standard_age,
    atlas=atlas,
)
print(" -----\n", "-----\n", "-----\n", "Standard completed\n", "-----\n", "-----\n", "-----\n")



############
# QC
############
print(" -----\n", "-----\n", "-----\n", "QC started\n", "-----\n", "-----\n", "-----\n")

from dhcp.func.pipeline import Pipeline

p = Pipeline(subid, sesid, workdir)

p.defaults = p.defaults.update(dc='dc')
p.qc()
p.report()
print(" -----\n", "-----\n", "-----\n", "QC completed\n", "-----\n", "-----\n", "-----\n")



