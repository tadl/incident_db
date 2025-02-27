function cancel_add_patron(){
    $('#add_patron').hide()
    $('#add_patron').find('input').val('')
    $('#add_patron_to_incident_button').show()
    var patrons_in_incident = $('.patron_violation_form').length;
    if(patrons_in_incident == 0){
        $('#no_patron_div').show() 
    }
    $('#save_incident_buttons').show()  
}
window.cancel_add_patron = cancel_add_patron


function save_patron(patron_id){
    function isEmpty(value){
        return value == null || value == "";
    }
    if (typeof patron_id === "undefined"){
        patron_id =''
    };

    var params = {}
    params['incident_id'] = $('#incident_id').html()
    params['first_name'] = $('#first_name_' + patron_id).val()
    params['middle_name'] = $('#middle_name_' + patron_id).val()
    params['last_name'] = $('#last_name_' + patron_id).val()
    params['known_as'] = $('#alias_' + patron_id).val()
    params['address'] = $('#address_' + patron_id).val()
    params['city'] = $('#city_' + patron_id).val()
    params['state'] = $('#state_' + patron_id).val()
    params['zip'] = $('#zip_' + patron_id).val()
    params['card_number'] = $('#card_number_' + patron_id).val()
    params['description'] = $('#patron_description_' + patron_id).val()

    var patron_params = new FormData()
    $.each(params, function(k,v){
        patron_params.append(k, v)
    });

    var patron_images = $('#patron_images_' + patron_id).prop("files");
    if(patron_images && patron_images[0]){
        $.each(patron_images, function(i){
            patron_params.append('images[]', this)
        });
    }

    if(patron_id){
        patron_params.append('patron_id', patron_id)
    }

    $.ajax({
        url: "/patrons/save.js",
        data: patron_params,
        type:'POST',
        contentType: false,
        processData: false,
    });
    $('#save_incident_buttons').show()
    $('#add_patron_to_incident_button').show()
}
window.save_patron = save_patron

function show_violation_modal(track, patron_id){
    var params = {}
    params['track'] = track
    params['patron_id'] = patron_id
    $.post("/patrons/load_violation_modal.js", params);
}
window.show_violation_modal = show_violation_modal

function save_violations(patron_id){
    var target_div = '#violation_modal_containter_' + patron_id + ' input:checked'
    var violations = [];
        $(target_div).each(function() {
        violations.push($(this).val());
    });
    var params = {}
    params['violation_ids'] = violations
    params['patron_id'] = patron_id
    params['incident_id'] = $('#incident_id').html()
    $.post("/patrons/save_violations.js", params);
}
window.save_violations = save_violations

function remove_violation(patron_id, violation_id){
    var params = {}
    params['incident_id'] = $('#incident_id').html()
    params['patron_id'] = patron_id
    params['violation_id'] = violation_id
    $.post("/patrons/remove_violation.js", params);
}
window.remove_violation = remove_violation

function remove_patron_from_incident(patron_id){
    var params = {}
    params['incident_id'] = $('#incident_id').html()
    params['patron_id'] = patron_id
    $.post("/patrons/remove_patron_from_incident.js", params);
}
window.remove_patron_from_incident = remove_patron_from_incident

function edit_patron(patron_id, from_incident){
    var params = {}
    params['from_inciden'] = from_incident
    params['incident_id'] = $('#incident_id').html()
    params['patron_id'] = patron_id
    $.post("/patrons/edit.js", params);
}
window.edit_patron = edit_patron

function cancel_patron_images(){
    $('#patron_images').val(null)
}
window.cancel_patron_images = cancel_patron_images

function delete_patron_image(image_id, patron_id){
    var params = {}
    params['patron_id'] = patron_id
    params['incident_id'] = $('#incident_id').html()
    params['image_id'] = image_id
    $.post("/patrons/delete_image.js", params);
}
window.delete_patron_image = delete_patron_image

function load_patron_search(){
    var params = {}
    params['incident_id'] = $('#incident_id').html()
    $.post("/patrons/load_patron_search.js", params);
}
window.load_patron_search = load_patron_search

function patron_search(from_incident){
    var params = {}
    params['query'] = $('#patron_query').val()
    if(from_incident == true){
        params['incident_id'] = $('#incident_id').html()
        $.post("/patrons/search.js", params);
    }else{
        if ($('#unknown_only').is(":checked")){
            params['unknown_only'] = true
        }else{
            params['unknown_only'] = false
        }
        window.location.href = '/patrons/search?query=' + params['query'] + '&unknown_only=' + params['unknown_only']
    }
}
window.patron_search = patron_search

function load_new_patron_form(){
    var params = {}
    params['incident_id'] = $('#incident_id').html()
    $.post("/patrons/load_new_patron_form.js", params);
}
window.load_new_patron_form = load_new_patron_form

function add_existing_to_incident(patron_id){
    var params = {}
    params['patron_id'] = patron_id
    params['incident_id'] = $('#incident_id').html()
    $.post("/patrons/add_existing_to_incident.js", params);
    $('#add_patron_to_incident_button').show()
}
window.add_existing_to_incident = add_existing_to_incident

function show_suspension_modal(patron_id){
    var params = {}
    params['patron_id'] = patron_id
    params['incident_id'] = $('#incident_id').html()
    $.post("/patrons/load_suspension_form.js", params);
}
window.show_suspension_modal = show_suspension_modal

function save_suspension(patron_id){
    var params = {}
    params['patron_id'] = patron_id
    params['incident_id'] = $('#incident_id').html()
    params['suspension_id'] = $('#suspension_id_' + patron_id ).html()
    params['until'] = $('#until_' + patron_id ).val()
    if ($('#letter_sent_' + patron_id).is(":checked")){
        params['letter_sent'] = true
    }else{
        params['letter_sent'] = false
    }
    if ($('#call_police_' + patron_id).is(":checked")){
        params['call_police'] = true
    }else{
        params['call_police'] = false
    }

    var suspension_params = new FormData()
    $.each(params, function(k,v){
        suspension_params.append(k, v)
    });

    if($('#letter_' + patron_id).length){
        var letter = $('#letter_' + patron_id).prop("files")[0] 
        if(letter){
            suspension_params.append('letter', letter ) 
        }
        
    }


    $.ajax({
        url: "/patrons/save_suspension.js",
        data: suspension_params,
        type:'POST',
        contentType: false,
        processData: false,
    });

}
window.save_suspension = save_suspension

function delete_suspension(suspension_id, patron_id, incident_id){
    var params = {}
    params['incident_id'] = incident_id
    params['suspension_id'] = suspension_id
    params['patron_id'] = patron_id
    $.post("/patrons/delete_suspension.js", params);
}
window.delete_suspension = delete_suspension

function cancel_suspension_letter(id){
    $('#letter_' + id).val(null)
}
window.cancel_suspension_letter = cancel_suspension_letter

function delete_letter(patron_id, suspension_id, incident_id){
    var params = {}
    params['incident_id'] = incident_id
    params['patron_id'] = patron_id
    params['suspension_id'] = suspension_id
    $.post("/patrons/delete_letter.js", params);
}
window.delete_letter = delete_letter

function delete_patron(patron_id){
    var confirmation = confirm("Are you sure you want to delete this patron?")
    if(confirmation == true){
        var params = {}
        params['id'] = patron_id
        $.post("/patrons/delete_patron.js", params);
    }
}
window.delete_patron = delete_patron