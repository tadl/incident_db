function no_name_check(self){
    if($(self).is(':checked')){
        $('#name_div').hide()
        $('#name_div').find('input').val('');
        $('#alias_div').show()
    }else{
        $('#name_div').show()
        $('#alias_div').hide()
        $('#alias_div').find('input').val('')
    }
}
window.no_name_check = no_name_check

function no_address_check(self){
    if($(self).is(':checked')){
        $('#address_div').hide()
        $('#address_div').find('input').val('')
    }else{
        $('#address_div').show()
    }
}
window.no_address_check = no_address_check

function cancel_add_patron(){
    $('#add_patron').hide()
    $('#add_patron').find('input').val('')
    $('#add_patron_to_incident_button').show()
    var patrons_in_incident = $('.patron_violation_form').length;
    if(patrons_in_incident == 0){
        $('#no_patron_div').show() 
    }  
}
window.cancel_add_patron = cancel_add_patron

function save_patron(){
    var params = {}
    params['first_name'] = $('#first_name').val()
    params['middle_name'] = $('#middle_name').val()
    params['last_name'] = $('#last_name').val()
    params['alias'] = $('#alias').val()
    params['address'] = $('#address').val()
    params['city'] = $('#city').val()
    params['state'] = $('#state').val()
    params['zip'] = $('#zip').val()
    params['card_number'] = $('#card_number').val()
    params['description'] = $('#patron_description').val()
    if($('#no_name').is(':checked')){
        params['no_name'] = true 
    }
    if($('#no_address').is(':checked')){
        params['no_address'] = true 
    }
    $.post("/patrons/save.js", params);
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