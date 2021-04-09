func! util#insert(zettelid, as_folgezettel)
	if a:as_folgezettel
		let l:formatted = "[[".a:zettelid."]]#"
	else
		let l:formatted = "[[".a:zettelid."]]"
	endif

	let l:word_under = expand('<cword>')
	if !empty(l:word_under) && empty(trim(l:word_under, "[]<>"))
		" erase things like '[[]]' before adding
		execute "normal! diwi".l:formatted
	else
		execute "normal! a".l:formatted
	endif

	call neuron#add_virtual_titles()
	let g:_neuron_must_refresh_on_write = 1
endf

func! util#is_zettelid_valid(zettelid)
	if empty(a:zettelid)
		return 0
	end
	if !empty(get(g:_neuron_zettels_titles_list, util#deform_zettelid(a:zettelid)))
		return 1
	else
		return 0
	end
endf

" returns a list of zettel IDs, their start and end positions in the line
func! util#get_zettel_in_line(line)
    let l:matched_zettel_ids = []
	for zettel in g:_neuron_zettels_by_id
		let l:matched = matchstrpos(a:line, '\[\['.zettel['id'].'\]\]')
		if !empty(l:matched)
			call add(l:matched_zettel_ids, [l:matched[0][2:-3], l:matched[1], l:matched[2]])
		end
	endfor
	return l:matched_zettel_ids
endf

func! util#get_zettel_from_fzf_line(line)
	return split(a:line, ":")[0]
endf

func! util#deform_zettelid(zettelid)
	if a:zettelid =~ "\[\[\[\?.*\]\]\]\?"
		return substitute(a:zettelid, '\[\[\[\?\([0-9a-zA-Z_-]\+\)\(?cf\)\?\]\]\]\?', '\1', 'g')
	else
		return a:zettelid
	end
endf

func! util#insert_shrink_fzf(line)
	call util#insert(util#get_zettel_from_fzf_line(a:line), 0)
endf

func! util#insert_shrink_fzf_folgezettel(line)
	call util#insert(util#get_zettel_from_fzf_line(a:line), 1)
endf

func! util#edit_shrink_fzf(line)
	call neuron#edit_zettel(util#get_zettel_from_fzf_line(a:line))
endf

func! util#zettel_date_sorter(a, b)
	let l:ad = util#zettel_date_getter(a:a)
	let l:bd = util#zettel_date_getter(a:b)
	if l:ad == l:bd
		return 0
	elseif l:ad > l:bd
		return -1
	else
		return 1
	endif
endf

func! util#zettel_date_getter(z)
    let l:datetime = get(a:z, 'Date')
    if type(l:datetime) != type([])
        let l:datetime = ['1970-01-01', '00:00:00']
    endif
	let l:date = get(l:datetime, 0, ['1970-01-01'])
	if type(l:date) != type([])
		let l:date = ['1970-01-01']
	endif
	return join(l:date)
endf

" get the fzf options
" optional params of:
" - the prompt to use, default 'Search zettel: '
" - whether to use preview, default True
" - fzf options to use if not the global ones
func! util#get_fzf_options(...)
	let l:ncol = (&columns - 4) / 2
	let l:ext = g:neuron_extension

	let l:prompt = get(a:, 1, 'Search zettel: ')
	let l:use_preview = get(a:, 2, 1)
	let l:ext_options = get(a:, 3, g:neuron_fzf_options)

	let l:options = extend(deepcopy(l:ext_options), ['--prompt', l:prompt])

	if l:use_preview == 1
		let l:options = extend(deepcopy(l:options), ['--preview', "echo {} | sed 's/:.*/".l:ext."/' | xargs fold -w ".l:ncol." -s"])
	endif

	return l:options
endf

func! util#current_zettel()
	return util#zettel_id_from_path(expand("%s"))
endf

func! util#zettel_id_from_path(path)
	return fnamemodify(a:path, ':t:r')
endf

func! util#new_zettel_path(title)
	return g:neuron_dir.util#generate_id(a:title).g:neuron_extension
endf

func! util#generate_id(title)
	let l:id = ""

	" mega-customization through functions to generate the zettel id
	if exists('*g:CustomNeuronIDGenerator')
		let l:id = g:CustomNeuronIDGenerator(a:title)
	endif

	if empty(l:id)
		let l:id = system("od -An -N 4 -t 'x4' /dev/random")
	endif

	return trim(l:id)
endfunc

func! util#add_empty_zettel_body(title)
	let l:body = [
	  \ '---',
	  \ 'date: '.strftime("%Y-%m-%dT%H:%M"),
	  \ '---',
	  \ '',
	  \ '# '.a:title
	\ ]
	call append(0, l:body)
endf
