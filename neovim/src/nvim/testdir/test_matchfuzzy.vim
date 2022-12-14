" Tests for fuzzy matching

source shared.vim
source check.vim

" Test for matchfuzzy()
func Test_matchfuzzy()
  call assert_fails('call matchfuzzy(10, "abc")', 'E686:')
  " Needs v8.2.1183; match the final error that's thrown for now
  " call assert_fails('call matchfuzzy(["abc"], [])', 'E730:')
  call assert_fails('call matchfuzzy(["abc"], [])', 'E475:')
  call assert_fails("let x = matchfuzzy(v:_null_list, 'foo')", 'E686:')
  call assert_fails('call matchfuzzy(["abc"], v:_null_string)', 'E475:')
  call assert_equal([], matchfuzzy([], 'abc'))
  call assert_equal([], matchfuzzy(['abc'], ''))
  call assert_equal(['abc'], matchfuzzy(['abc', 10], 'ac'))
  call assert_equal([], matchfuzzy([10, 20], 'ac'))
  call assert_equal(['abc'], matchfuzzy(['abc'], 'abc'))
  call assert_equal(['crayon', 'camera'], matchfuzzy(['camera', 'crayon'], 'cra'))
  call assert_equal(['aabbaa', 'aaabbbaaa', 'aaaabbbbaaaa', 'aba'], matchfuzzy(['aba', 'aabbaa', 'aaabbbaaa', 'aaaabbbbaaaa'], 'aa'))
  call assert_equal(['one'], matchfuzzy(['one', 'two'], 'one'))
  call assert_equal(['oneTwo', 'onetwo'], matchfuzzy(['onetwo', 'oneTwo'], 'oneTwo'))
  call assert_equal(['onetwo', 'one_two'], matchfuzzy(['onetwo', 'one_two'], 'oneTwo'))
  call assert_equal(['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'], matchfuzzy(['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'], 'aa'))
  call assert_equal(256, matchfuzzy([repeat('a', 256)], repeat('a', 256))[0]->len())
  call assert_equal([], matchfuzzy([repeat('a', 300)], repeat('a', 257)))
  " matches with same score should not be reordered
  let l = ['abc1', 'abc2', 'abc3']
  call assert_equal(l, l->matchfuzzy('abc'))

  " Tests for match preferences
  " preference for camel case match
  call assert_equal(['oneTwo', 'onetwo'], ['onetwo', 'oneTwo']->matchfuzzy('onetwo'))
  " preference for match after a separator (_ or space)
  call assert_equal(['onetwo', 'one_two', 'one two'], ['onetwo', 'one_two', 'one two']->matchfuzzy('onetwo'))
  " preference for leading letter match
  call assert_equal(['onetwo', 'xonetwo'], ['xonetwo', 'onetwo']->matchfuzzy('onetwo'))
  " preference for sequential match
  call assert_equal(['onetwo', 'oanbectdweo'], ['oanbectdweo', 'onetwo']->matchfuzzy('onetwo'))
  " non-matching leading letter(s) penalty
  call assert_equal(['xonetwo', 'xxonetwo'], ['xxonetwo', 'xonetwo']->matchfuzzy('onetwo'))
  " total non-matching letter(s) penalty
  call assert_equal(['one', 'onex', 'onexx'], ['onexx', 'one', 'onex']->matchfuzzy('one'))
  " prefer complete matches over separator matches
  call assert_equal(['.vim/vimrc', '.vim/vimrc_colors', '.vim/v_i_m_r_c'], ['.vim/vimrc', '.vim/vimrc_colors', '.vim/v_i_m_r_c']->matchfuzzy('vimrc'))
  " gap penalty
  call assert_equal(['xxayybxxxx', 'xxayyybxxx', 'xxayyyybxx'], ['xxayyyybxx', 'xxayyybxxx', 'xxayybxxxx']->matchfuzzy('ab'))
  " path separator vs word separator
  call assert_equal(['color/setup.vim', 'color\\setup.vim', 'color setup.vim', 'color_setup.vim', 'colorsetup.vim'], matchfuzzy(['colorsetup.vim', 'color setup.vim', 'color/setup.vim', 'color_setup.vim', 'color\\setup.vim'], 'setup.vim'))

  " match multiple words (separated by space)
  call assert_equal(['foo bar baz'], ['foo bar baz', 'foo', 'foo bar', 'baz bar']->matchfuzzy('baz foo'))
  call assert_equal([], ['foo bar baz', 'foo', 'foo bar', 'baz bar']->matchfuzzy('one two'))
  call assert_equal([], ['foo bar']->matchfuzzy(" \t "))

  " test for matching a sequence of words
  call assert_equal(['bar foo'], ['foo bar', 'bar foo', 'foobar', 'barfoo']->matchfuzzy('bar foo', {'matchseq' : 1}))
  call assert_equal([#{text: 'two one'}], [#{text: 'one two'}, #{text: 'two one'}]->matchfuzzy('two one', #{key: 'text', matchseq: v:true}))

  %bw!
  eval ['somebuf', 'anotherone', 'needle', 'yetanotherone']->map({_, v -> bufadd(v) + bufload(v)})
  let l = getbufinfo()->map({_, v -> v.name})->matchfuzzy('ndl')
  call assert_equal(1, len(l))
  call assert_match('needle', l[0])

  " Test for fuzzy matching dicts
  let l = [{'id' : 5, 'val' : 'crayon'}, {'id' : 6, 'val' : 'camera'}]
  call assert_equal([{'id' : 6, 'val' : 'camera'}], matchfuzzy(l, 'cam', {'text_cb' : {v -> v.val}}))
  call assert_equal([{'id' : 6, 'val' : 'camera'}], matchfuzzy(l, 'cam', {'key' : 'val'}))
  call assert_equal([], matchfuzzy(l, 'day', {'text_cb' : {v -> v.val}}))
  call assert_equal([], matchfuzzy(l, 'day', {'key' : 'val'}))
  call assert_fails("let x = matchfuzzy(l, 'cam', 'random')", 'E715:')
  call assert_equal([], matchfuzzy(l, 'day', {'text_cb' : {v -> []}}))
  call assert_equal([], matchfuzzy(l, 'day', {'text_cb' : {v -> 1}}))
  call assert_fails("let x = matchfuzzy(l, 'day', {'text_cb' : {a, b -> 1}})", 'E119:')
  call assert_equal([], matchfuzzy(l, 'cam'))
  " Nvim's callback implementation is different, so E6000 is expected instead,
  " but we need v8.2.1183 to assert it
  " call assert_fails("let x = matchfuzzy(l, 'cam', {'text_cb' : []})", 'E921:')
  " call assert_fails("let x = matchfuzzy(l, 'cam', {'text_cb' : []})", 'E6000:')
  call assert_fails("let x = matchfuzzy(l, 'cam', {'text_cb' : []})", 'E475:')
  " call assert_fails("let x = matchfuzzy(l, 'foo', {'key' : []})", 'E730:')
  call assert_fails("let x = matchfuzzy(l, 'foo', {'key' : []})", 'E475:')
  call assert_fails("let x = matchfuzzy(l, 'cam', v:_null_dict)", 'E715:')
  call assert_fails("let x = matchfuzzy(l, 'foo', {'key' : v:_null_string})", 'E475:')
  " Nvim doesn't have null functions
  " call assert_fails("let x = matchfuzzy(l, 'foo', {'text_cb' : test_null_function()})", 'E475:')
  " matches with same score should not be reordered
  let l = [#{text: 'abc', id: 1}, #{text: 'abc', id: 2}, #{text: 'abc', id: 3}]
  call assert_equal(l, l->matchfuzzy('abc', #{key: 'text'}))

  let l = [{'id' : 5, 'name' : 'foo'}, {'id' : 6, 'name' : []}, {'id' : 7}]
  call assert_fails("let x = matchfuzzy(l, 'foo', {'key' : 'name'})", 'E730:')

  " Test in latin1 encoding
  let save_enc = &encoding
  " Nvim supports utf-8 encoding only
  " set encoding=latin1
  call assert_equal(['abc'], matchfuzzy(['abc'], 'abc'))
  let &encoding = save_enc
endfunc

" Test for the matchfuzzypos() function
func Test_matchfuzzypos()
  call assert_equal([['curl', 'world'], [[2,3], [2,3]], [128, 127]], matchfuzzypos(['world', 'curl'], 'rl'))
  call assert_equal([['curl', 'world'], [[2,3], [2,3]], [128, 127]], matchfuzzypos(['world', 'one', 'curl'], 'rl'))
  call assert_equal([['hello', 'hello world hello world'],
        \ [[0, 1, 2, 3, 4], [0, 1, 2, 3, 4]], [275, 257]],
        \ matchfuzzypos(['hello world hello world', 'hello', 'world'], 'hello'))
  call assert_equal([['aaaaaaa'], [[0, 1, 2]], [191]], matchfuzzypos(['aaaaaaa'], 'aaa'))
  call assert_equal([['a  b'], [[0, 3]], [219]], matchfuzzypos(['a  b'], 'a  b'))
  call assert_equal([['a  b'], [[0, 3]], [219]], matchfuzzypos(['a  b'], 'a    b'))
  call assert_equal([['a  b'], [[0]], [112]], matchfuzzypos(['a  b'], '  a  '))
  call assert_equal([[], [], []], matchfuzzypos(['a  b'], '  '))
  call assert_equal([[], [], []], matchfuzzypos(['world', 'curl'], 'ab'))
  let x = matchfuzzypos([repeat('a', 256)], repeat('a', 256))
  call assert_equal(range(256), x[1][0])
  call assert_equal([[], [], []], matchfuzzypos([repeat('a', 300)], repeat('a', 257)))
  call assert_equal([[], [], []], matchfuzzypos([], 'abc'))

  " match in a long string
  call assert_equal([[repeat('x', 300) .. 'abc'], [[300, 301, 302]], [-135]],
        \ matchfuzzypos([repeat('x', 300) .. 'abc'], 'abc'))

  " preference for camel case match
  call assert_equal([['xabcxxaBc'], [[6, 7, 8]], [189]], matchfuzzypos(['xabcxxaBc'], 'abc'))
  " preference for match after a separator (_ or space)
  call assert_equal([['xabx_ab'], [[5, 6]], [145]], matchfuzzypos(['xabx_ab'], 'ab'))
  " preference for leading letter match
  call assert_equal([['abcxabc'], [[0, 1]], [150]], matchfuzzypos(['abcxabc'], 'ab'))
  " preference for sequential match
  call assert_equal([['aobncedone'], [[7, 8, 9]], [158]], matchfuzzypos(['aobncedone'], 'one'))
  " best recursive match
  call assert_equal([['xoone'], [[2, 3, 4]], [168]], matchfuzzypos(['xoone'], 'one'))

  " match multiple words (separated by space)
  call assert_equal([['foo bar baz'], [[8, 9, 10, 0, 1, 2]], [369]], ['foo bar baz', 'foo', 'foo bar', 'baz bar']->matchfuzzypos('baz foo'))
  call assert_equal([[], [], []], ['foo bar baz', 'foo', 'foo bar', 'baz bar']->matchfuzzypos('one two'))
  call assert_equal([[], [], []], ['foo bar']->matchfuzzypos(" \t "))
  call assert_equal([['grace'], [[1, 2, 3, 4, 2, 3, 4, 0, 1, 2, 3, 4]], [657]], ['grace']->matchfuzzypos('race ace grace'))

  let l = [{'id' : 5, 'val' : 'crayon'}, {'id' : 6, 'val' : 'camera'}]
  call assert_equal([[{'id' : 6, 'val' : 'camera'}], [[0, 1, 2]], [192]],
        \ matchfuzzypos(l, 'cam', {'text_cb' : {v -> v.val}}))
  call assert_equal([[{'id' : 6, 'val' : 'camera'}], [[0, 1, 2]], [192]],
        \ matchfuzzypos(l, 'cam', {'key' : 'val'}))
  call assert_equal([[], [], []], matchfuzzypos(l, 'day', {'text_cb' : {v -> v.val}}))
  call assert_equal([[], [], []], matchfuzzypos(l, 'day', {'key' : 'val'}))
  call assert_fails("let x = matchfuzzypos(l, 'cam', 'random')", 'E715:')
  call assert_equal([[], [], []], matchfuzzypos(l, 'day', {'text_cb' : {v -> []}}))
  call assert_equal([[], [], []], matchfuzzypos(l, 'day', {'text_cb' : {v -> 1}}))
  call assert_fails("let x = matchfuzzypos(l, 'day', {'text_cb' : {a, b -> 1}})", 'E119:')
  call assert_equal([[], [], []], matchfuzzypos(l, 'cam'))
  " Nvim's callback implementation is different, so E6000 is expected instead,
  " but we need v8.2.1183 to assert it
  " call assert_fails("let x = matchfuzzypos(l, 'cam', {'text_cb' : []})", 'E921:')
  " call assert_fails("let x = matchfuzzypos(l, 'cam', {'text_cb' : []})", 'E6000:')
  call assert_fails("let x = matchfuzzypos(l, 'cam', {'text_cb' : []})", 'E475:')
  " call assert_fails("let x = matchfuzzypos(l, 'foo', {'key' : []})", 'E730:')
  call assert_fails("let x = matchfuzzypos(l, 'foo', {'key' : []})", 'E475:')
  call assert_fails("let x = matchfuzzypos(l, 'cam', v:_null_dict)", 'E715:')
  call assert_fails("let x = matchfuzzypos(l, 'foo', {'key' : v:_null_string})", 'E475:')
  " Nvim doesn't have null functions
  " call assert_fails("let x = matchfuzzypos(l, 'foo', {'text_cb' : test_null_function()})", 'E475:')

  let l = [{'id' : 5, 'name' : 'foo'}, {'id' : 6, 'name' : []}, {'id' : 7}]
  call assert_fails("let x = matchfuzzypos(l, 'foo', {'key' : 'name'})", 'E730:')
endfunc

" Test for matchfuzzy() with multibyte characters
func Test_matchfuzzy_mbyte()
  CheckFeature multi_lang
  call assert_equal(['???????????????'], matchfuzzy(['???????????????'], '??????'))
  " reverse the order of characters
  call assert_equal([], matchfuzzy(['???????????????'], '??????'))
  call assert_equal(['??????xxx', 'x??x??x??x'],
        \ matchfuzzy(['??????xxx', 'x??x??x??x'], '??????'))
  call assert_equal(['????bb????', '??????bbb??????', '????????bbbb????????', '??b??'],
        \ matchfuzzy(['??b??', '????bb????', '??????bbb??????', '????????bbbb????????'], '????'))

  " match multiple words (separated by space)
  call assert_equal(['??? ????????? ?????? ??????'], ['??? ????????? ?????? ??????', '?????????', '????????? ??????', '?????? ??????']->matchfuzzy('?????? ?????????'))
  call assert_equal([], ['??? ????????? ?????? ??????', '?????????', '????????? ??????', '?????? ??????']->matchfuzzy('?????? ??????'))

  " preference for camel case match
  call assert_equal(['one??wo', 'one??wo'],
        \ ['one??wo', 'one??wo']->matchfuzzy('one??wo'))
  " preference for complete match then match after separator (_ or space)
  call assert_equal(['??????ab??????'] + sort(['??????a_b??????', '??????a b??????']),
          \ ['??????ab??????', '??????a b??????', '??????a_b??????']->matchfuzzy('??????ab??????'))
  " preference for match after a separator (_ or space)
  call assert_equal(['??????ab??????', '??????a_b??????', '??????a b??????'],
        \ ['??????a_b??????', '??????a b??????', '??????ab??????']->matchfuzzy('??????ab??????'))
  " preference for leading letter match
  call assert_equal(['????????????', 'x????????????'],
        \ ['x????????????', '????????????']->matchfuzzy('????????????'))
  " preference for sequential match
  call assert_equal(['??????????????????', '???a???b???c???d???e???'],
        \ ['???a???b???c???d???e???', '??????????????????']->matchfuzzy('??????????????????'))
  " non-matching leading letter(s) penalty
  call assert_equal(['x??????????????????', 'xx??????????????????'],
        \ ['xx??????????????????', 'x??????????????????']->matchfuzzy('??????????????????'))
  " total non-matching letter(s) penalty
  call assert_equal(['??????', '??????x', '??????xx'],
        \ ['??????xx', '??????', '??????x']->matchfuzzy('??????'))
endfunc

" Test for matchfuzzypos() with multibyte characters
func Test_matchfuzzypos_mbyte()
  CheckFeature multi_lang
  call assert_equal([['?????????????????????'], [[0, 1, 2, 3, 4]], [273]],
        \ matchfuzzypos(['?????????????????????'], '???????????????'))
  call assert_equal([['???????????????'], [[1, 3]], [88]], matchfuzzypos(['???????????????'], '??????'))
  " reverse the order of characters
  call assert_equal([[], [], []], matchfuzzypos(['???????????????'], '??????'))
  call assert_equal([['??????xxx', 'x??x??x??x'], [[0, 1, 2], [1, 3, 5]], [222, 113]],
        \ matchfuzzypos(['??????xxx', 'x??x??x??x'], '??????'))
  call assert_equal([['????bb????', '??????bbb??????', '????????bbbb????????', '??b??'],
        \ [[0, 1], [0, 1], [0, 1], [0, 2]], [151, 148, 145, 110]],
        \ matchfuzzypos(['??b??', '????bb????', '??????bbb??????', '????????bbbb????????'], '????'))
  call assert_equal([['??????????????'], [[0, 1, 2]], [191]],
        \ matchfuzzypos(['??????????????'], '??????'))

  call assert_equal([[], [], []], matchfuzzypos(['?????????', '??????'], '?????????'))
  let x = matchfuzzypos([repeat('??', 256)], repeat('??', 256))
  call assert_equal(range(256), x[1][0])
  call assert_equal([[], [], []], matchfuzzypos([repeat('???', 300)], repeat('???', 257)))

  " match multiple words (separated by space)
  call assert_equal([['??? ????????? ?????? ??????'], [[9, 10, 2, 3, 4]], [328]], ['??? ????????? ?????? ??????', '?????????', '????????? ??????', '?????? ??????']->matchfuzzypos('?????? ?????????'))
  call assert_equal([[], [], []], ['??? ????????? ?????? ??????', '?????????', '????????? ??????', '?????? ??????']->matchfuzzypos('?????? ??????'))

  " match in a long string
  call assert_equal([[repeat('???', 300) .. '?????????'], [[300, 301, 302]], [-135]],
        \ matchfuzzypos([repeat('???', 300) .. '?????????'], '?????????'))
  " preference for camel case match
  call assert_equal([['x??????xx??????'], [[6, 7, 8]], [189]], matchfuzzypos(['x??????xx??????'], '??????'))
  " preference for match after a separator (_ or space)
  call assert_equal([['x??????x_??????'], [[5, 6]], [145]], matchfuzzypos(['x??????x_??????'], '??????'))
  " preference for leading letter match
  call assert_equal([['??????x??????'], [[0, 1]], [150]], matchfuzzypos(['??????x??????'], '????'))
  " preference for sequential match
  call assert_equal([['a???b???c???d?????????'], [[7, 8, 9]], [158]], matchfuzzypos(['a???b???c???d?????????'], '?????????'))
  " best recursive match
  call assert_equal([['x????????'], [[2, 3, 4]], [168]], matchfuzzypos(['x????????'], '??????'))
endfunc

" vim: shiftwidth=2 sts=2 expandtab
