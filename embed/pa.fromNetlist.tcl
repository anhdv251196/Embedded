
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name embed -dir "/home/ise/Machine_VB/embed/embed/planAhead_run_2" -part xc3s50avq100-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/ise/Machine_VB/embed/embed/top_embed.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/ise/Machine_VB/embed/embed} {../ipcore} }
add_files [list {../ipcore/divide.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {../ipcore/fifo_ccd.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "/home/ise/Machine_VB/embed/ucf/embed.ucf" [current_fileset -constrset]
add_files [list {/home/ise/Machine_VB/embed/ucf/embed.ucf}] -fileset [get_property constrset [current_run]]
link_design
