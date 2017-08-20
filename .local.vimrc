execute 'set runtimepath+=' . expand('%:p:h')
runtime plugin/vimdbb.vim

Remap n <Space>ds <Plug>(vimdbb-start)
Remap n <Space>dd <Plug>(vimdbb-run)
