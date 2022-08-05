function save_incident(draft, add_patron){
    var params = {}
    params['title'] = $('#title').val()
    params['description'] = $('#description').val()
    params['date_of'] = picker.viewDate
    params['location'] = $('#location').val()
    if(draft == 'true'){
        params['draft'] = true
    }
    if(add_patron == 'true'){
        params['add_patron'] = true 
    }
    if($('#no_patrons').is(':checked')){
        params['no_patrons'] = true 
    }
    params['id'] = $('#incident_id').html()
    $.post("/incidents/save.js", params);
}
window.save_incident = save_incident