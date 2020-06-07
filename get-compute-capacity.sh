#!/usr/bin/env bash
###############################################################################
#
# get-compute-capacity - a script to get compute capacity from OCI.
#
###############################################################################

function get_valid_shapes() {
    echo "Get types of compute shapes"
    echo "$ oci compute shape list"
    oci compute shape list | jq -r .data[].shape | sort | uniq
}

function list_instances() {
    # list_instances( compartment_id )
    local pc
    [[ ${1} ]] && pc=${1} || [[ ${prod_compartment} ]] && pc=${prod_compartment}
    [[ ! {pc} ]] && echo "$0 called without a compartment ID" && return 1
    echo "List running instances in the production compartment"
    echo "$ oci compute instance list --compartment-id ${pc}"
    oci compute instance list --compartment-id "${pc}"
}

function get_parms() {
    echo "Get shape types with non-zero limits"
    echo "oci limits value list --service-name compute --all | grep and sed for non-zero"
    export available_shapes="$(oci limits value list --service-name compute --all | \
    	   jq -r .data[].name | grep vm | sort | uniq | tr '-' '.' | tr "mv" "MV" | sed 's/\.s\(.*\).count/\.S\1/')"
    echo ${available_shapes}

    echo "Get the list of valid ADs"
    export available_ads="$(oci iam availability-domain list | jq -r .data[].name)"
    echo ${available_ads}

    echo "Get the id of the prod compartment"
    export prod_compartment=$(oci iam compartment list | jq -r '.data[] | select(.name=="prod") | ."compartment-id"')
    echo ${prod_compartment}

    echo "Get the right image"
    export image_id=$(oci compute image list --compartment-id $OCI_COMPARTMENT_PROD --all | \
	   jq -r '.data[] | select(."operating-system"=="Oracle Linux") | select(."operating-system-version"=="7.7") | ."id"' | tail -n1)
    echo ${image_id}

    echo "Get the VCN"
    export vcn=$(oci network vcn list | jq -r '.data[]."id"')
    echo ${vcn}

    echo "And from that the subnet"
    export subnet_id=$(oci network subnet list --vcn-id ${vcn} --compartment-id ${prod_compartment} | \
			   jq -r '.data[]."id"')
    echo ${subnet_id}
}

function launch_capacity() {
    while IFS= read -r i; do
	while IFS= read -r j; do
	    oci compute instance launch \
		--shape ${i} \
		--availability-domain ${j} \
		--compartment-id ${prod_compartment} \
		--image-id ${image_id} \
		--subnet-id ${subnet_id}
	done <<< "${available_ads}"
    done <<< "${available_shapes}"
}

if [[ "${1}" == "-f" ]]; then
    get_parms
    launch_capacity
else
    get_parms
    oci compute instance launch \
	--region sa-saopaulo-1 \
	--availability-domain Tdhb:SA-SAOPAULO-1-AD-1 \
	--shape VM.Standard.E2.1.Micro \
	--compartment-id ${OCI_COMPARTMENT_PROD} \
	--image-id ocid1.image.oc1.phx.aaaaaaaacy7j7ce45uckgt7nbahtsatih4brlsa2epp5nzgheccamdsea2yq \
	--subnet-id ${OCI_SUBNET} | jq
fi

# 	--availability-domain Tdhb:PHX-AD-3 \


