function save_incident(draft){
    var params = {}
    params['title'] = $('#title').val()
    params['description'] = $('#description').val()
    params['date_of'] = picker.viewDate
    params['location'] = $('#location').val()
    if(draft){
        params['draft'] = true
    }
    $.post("/incidents/save.js", params);
}
window.save_incident = save_incident