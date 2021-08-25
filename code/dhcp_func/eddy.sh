mkdir /home/johann.drayne/dhcp_func/eddy_output/
#
#/usr/local/fsl/bin/eddy_cuda \
# --imain=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/import/func.nii.gz \
# --mask=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/import/func_brainmask.nii.gz \
# --index=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/mcdc/index.txt \
# --bvals=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/mcdc/bvals \
# --bvecs=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/mcdc/bvecs \
# --acqp=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/mcdc/eddy.acqp \
# --out=/home/johann.drayne/dhcp_func/eddy_output/func_mcdc \
# --very_verbose \
# --estimate_move_by_susceptibility \
# --data_is_shelled \
# --mbs_niter=20 \
# --mbs_lambda=5 \
# --mbs_ksp=5 \
# --niter=10 \
# --fwhm=10,10,5,5,0,0,0,0,0,0 \
# --s2v_fwhm=0 \
# --s2v_niter=30 \
# --s2v_interp=trilinear \
# --mporder=0 \
# --nvoxhp=1000 \
# --slspec=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/import/func.slorder \
# --field=/home/johann.drayne/dhcp_func/dhcp_func_output/v02/sub-MS040064/ses-session1/mcdc/fmap_to_func_img_Hz \
# --b0_only \
# --field_mat=/usr/local/fsl/etc/flirtsch/ident.mat \
# --dont_mask_output \
# --s2v_lambda=10


/usr/local/fsl/bin/eddy_cuda \
 --imain=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/import/func.nii.gz \
 --mask=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/import/func_brainmask.nii.gz \
 --index=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/mcdc/index.txt \
 --bvals=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/mcdc/bvals \
 --bvecs=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/mcdc/bvecs \
 --acqp=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/mcdc/eddy.acqp \
 --out=/home/johann.drayne/dhcp_func/eddy_output/func_mcdc \
 --very_verbose \
 --estimate_move_by_susceptibility \
 --data_is_shelled \
 --mbs_niter=20 \
 --mbs_lambda=5 \
 --mbs_ksp=5 \
 --niter=10 \
 --fwhm=10,10,5,5,0,0,0,0,0,0 \
 --s2v_fwhm=0 \
 --s2v_niter=10 \
 --s2v_interp=trilinear \
 --mporder=16 \
 --nvoxhp=1000 \
 --slspec=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/import/func.slorder \
 --field=/home/johann.drayne/dhcp_func/dhcp_func_output-training/v02/sub-MS040060/ses-session1/mcdc/fmap_to_func_img_Hz \
 --b0_only \
 --field_mat=/usr/local/fsl/etc/flirtsch/ident.mat \
 --dont_mask_output \
 --s2v_lambda=1
