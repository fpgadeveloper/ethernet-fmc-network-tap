'''
Opsero Electronic Design Inc.

data.json is intended to be a centralized source of information regarding all of the target
designs and it ensures that the documentation and makefiles are consistent.
When data.json is updated with new information, this Python script can be run to update
the main README.md file of the repo, the makefiles and the .gitignore. We typically
use this script when adding/removing target designs.

The Sphinx documentation also refers to the data.json file when compiling the target design
and supported board tables.
'''

import os
import json

# Load the JSON data
def load_json(filename):
    with open(filename) as f:
        return json.load(f)

def get_root_targets(data):
    templates = {'fpga': 'microblaze', 'z7': 'zynq', 'zu': 'zynqMP', 'versal': 'versal'}
    targets = []
    targets.append('BD_NAME = {}'.format(data['bd_name']))
    for design in data['designs']:
        template = templates[design['group']]
        if design['petalinux']:
            sw = 'both'
        else:
            sw = 'baremetal_only'
        target = '{}_target := {} {}'.format(design['label'],template,sw)
        targets.append(target)
    return(targets)

def get_vivado_targets(data):
    targets = []
    targets.append('BD_NAME = {}'.format(data.get('vivado_bd_name', data['bd_name'])))
    targets += ['{}_target := 0'.format(design['label']) for design in data['designs']]
    return(targets)

def get_vivado_build_targets(data):
    targets = []
    for design in data['designs']:
        target = 'dict set target_dict {} {{ {} {} {} {} }}'.format(design['label'],design['url'],design['boardname'],
            design['bdscript'],design['lanecfg'])
        targets.append(target)
    return(targets)

def get_vitis_targets(data, args):
    templates = {'fpga': 'microblaze', 'z7': 'zynq', 'zu': 'zynqMP', 'versal': 'versal'}
    targets = []
    # Global settings from args.json
    targets.append('BD_NAME = {}'.format(args['bd_name']))
    targets.append('APP_NAME = {}'.format(args.get('app_name', 'test_app')))
    combine = str(args.get('combine_bit_elf', True)).lower()
    targets.append('COMBINE_BIT_ELF = {}'.format(combine))
    # Per-target arch assignments
    for design in data['designs']:
        if not design['baremetal']:
            continue
        template = templates[design['group']]
        target = '{}_target := {}'.format(design['label'],template)
        targets.append(target)
    return(targets)

def get_ignore_paths(data):
    paths = []
    for design in data['designs']:
        p = 'Vivado/{}/'.format(design['label'])
        paths.append(p)
    return(paths)

# Update a file that uses "# UPDATER START" and "# UPDATER END" tags
def update_file(file_path,targets):
    # Read the content of the file
    with open(file_path, 'r') as infile:
        lines = infile.readlines()

    # Open the same file in write mode to overwrite it
    with open(file_path, 'w') as outfile:
        inside_updater = False

        for line in lines:
            if '# UPDATER START' in line:
                # Write the start tag to the file
                outfile.write(line)
                # Write the targets
                for l in targets:
                    outfile.write("{}\n".format(l))
                inside_updater = True
            elif '# UPDATER END' in line:
                # Write the end tag to the file
                outfile.write(line)
                inside_updater = False
            elif not inside_updater:
                # Write the line if not inside the updater block
                outfile.write(line)

# Make sure that there is a constraints file for all target designs
def check_constraints(data):
    for design in data['designs']:
        filename = '../Vivado/src/constraints/{}.xdc'.format(design['label'])
        if not os.path.isfile(filename):
            print('WARNING: No constraints file found for target',design['label'])

# Read the JSON data
data = load_json('data.json')
args = load_json('../Vitis/py/args.json')

# Update the root makefile
root_makefile = '../Makefile'
root_targets = get_root_targets(data)
update_file(root_makefile,root_targets)

# Update the Vivado makefile
vivado_makefile = '../Vivado/Makefile'
vivado_targets = get_vivado_targets(data)
update_file(vivado_makefile,vivado_targets)

# Update the Vivado build.tcl
vivado_build_tcl = '../Vivado/scripts/build.tcl'
vivado_build_targets = get_vivado_build_targets(data)
update_file(vivado_build_tcl,vivado_build_targets)

# Update the Vitis makefile
vitis_makefile = '../Vitis/Makefile'
vitis_targets = get_vitis_targets(data, args)
update_file(vitis_makefile,vitis_targets)

## Update the PetaLinux makefile
#petalinux_makefile = '../PetaLinux/Makefile'
#petalinux_targets = get_petalinux_targets(data)
#update_file(petalinux_makefile,petalinux_targets)

# Update the gitignore
gitignore = '../.gitignore'
gitignore_paths = get_ignore_paths(data)
update_file(gitignore,gitignore_paths)

# Check constraints
check_constraints(data)
