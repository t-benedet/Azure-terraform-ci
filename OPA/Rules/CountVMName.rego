package main

#import data.terraform.module

vm_name = input.planned_values.root_module.resources[0].values.name

violation[{"message": "VM name must have exactly 13 characters."}] {
  count(vm_name) != 13
}
