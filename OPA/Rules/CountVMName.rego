package main

vm_name = input.planned_values.root_module.resources[0].values.name
vm_name_length = count(vm_name)

default msg := "Not ok"

msg := "OK" {
    vm_name_length == 13
}
