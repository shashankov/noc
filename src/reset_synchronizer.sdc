# SDC False Path constraints for reset synchronizer

proc apply_sdc_pre_reset_synchronizer {entity_name} {
set inst_list [get_entity_instances $entity_name]
foreach each_inst $inst_list {
        set_false_path -to ${each_inst}|reset_async*
    }
}
apply_sdc_pre_reset_synchronizer reset_synchronizer