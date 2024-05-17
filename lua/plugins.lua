return {
  {
    "nvim-lualine/lualine.nvim", -- Statusline
    config = function()
      require("lualine").setup {
        options = {
          icons_enabled = true,
          theme = 'tokyonight',
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
          disabled_filetypes = {}
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = {
            {
              function()
                local ollama_status = require("ollama").status()
                local icons = {
                  "󱙺", -- nf-md-robot-outline
                  "󰚩" -- nf-md-robot
                }

                if ollama_status == "IDLE" then
                  return icons[1]
                elseif ollama_status == "WORKING" then
                  return icons[os.date("%S") % #icons + 1] -- animation
                end
              end,
              cond = function()
                return package.loaded["ollama"] and require("ollama").status() ~= nil
              end,
            },
            {
              'filename',
              file_status = true, -- displays file status (readonly status, modified status)
              path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
            },
          },
          lualine_x = {
            { 'diagnostics', sources = { "nvim_diagnostic" }, symbols = { error = ' ', warn = ' ', info = ' ', hint = '' } },
            'encoding',
            'filetype'
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { {
            'filename',
            file_status = true, -- displays file status (readonly status, modified status)
            path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
          } },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        extensions = { 'fugitive' }
      }
    end
  },
  "nvim-lua/plenary.nvim",  -- Common utilities
  {
    "onsails/lspkind-nvim", -- vscode-like pictograms
    config = function()
      require("lspkind").init({
        -- enables text annotations
        --
        -- default: true
        mode = 'symbol',

        -- default symbol map
        -- can be either 'default' (requires nerd-fonts font) or
        -- 'codicons' for codicon preset (requires vscode-codicons font)
        --
        -- default: 'default'
        preset = 'codicons',

        -- override preset symbols
        --
        -- default: {}
        symbol_map = {
          Text = "",
          Method = "",
          Function = "",
          Constructor = "",
          Field = "ﰠ",
          Variable = "",
          Class = "ﴯ",
          Interface = "",
          Module = "",
          Property = "ﰠ",
          Unit = "塞",
          Value = "",
          Enum = "",
          Keyword = "",
          Snippet = "",
          Color = "",
          File = "",
          Reference = "",
          Folder = "",
          EnumMember = "",
          Constant = "",
          Struct = "פּ",
          Event = "",
          Operator = "",
          TypeParameter = ""
        },
      })
    end
  },
  "hrsh7th/cmp-buffer",   -- nvim-cmp source for buffer words
  "hrsh7th/cmp-nvim-lsp", -- nvim-cmp source for neovim"s built-in LSP
  {
    "hrsh7th/nvim-cmp",   -- Completion
    config = function()
      -- local lspkind = require 'lspkind'

      -- local function formatForTailwindCSS(entry, vim_item)
      --   if vim_item.kind == 'Color' and entry.completion_item.documentation then
      --     local _, _, r, g, b = string.find(entry.completion_item.documentation, '^rgb%((%d+), (%d+), (%d+)')
      --     if r then
      --       local color = string.format('%02x', r) .. string.format('%02x', g) .. string.format('%02x', b)
      --       local group = 'Tw_' .. color
      --       if vim.fn.hlID(group) < 1 then
      --         vim.api.nvim_set_hl(0, group, { fg = '#' .. color })
      --       end
      --       vim_item.kind = "●"
      --       vim_item.kind_hl_group = group
      --       return vim_item
      --     end
      --   end
      --   vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
      --   return vim_item
      -- end

      local cmp = require("cmp")

      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.close(),
          ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true
          }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
        }),
        -- formatting = {
        --   format = lspkind.cmp_format({
        --     maxwidth = 50,
        --     before = function(entry, vim_item)
        --       vim_item = formatForTailwindCSS(entry, vim_item)
        --       return vim_item
        --     end
        --   })
        -- }
      })

      vim.cmd [[
  set completeopt=menuone,noinsert,noselect
  highlight! default link CmpItemKind CmpItemMenuDefault
]]
    end
  },
  {
    "neovim/nvim-lspconfig", -- Quickstart configs for Nvim LSP
    config = function()
      --vim.lsp.set_log_level("debug")

      local nvim_lsp = require("lspconfig")

      local protocol = require('vim.lsp.protocol')

      local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })
      local enable_format_on_save = function(_, bufnr)
        vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup_format,
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ bufnr = bufnr })
          end,
        })
      end

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

        --Enable completion triggered by <c-x><c-o>
        --local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
        --buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        local opts = { noremap = true, silent = true }

        -- See `:help vim.lsp.*` for documentation on any of the below functions
        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        --buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        --buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
      end

      protocol.CompletionItemKind = {
        '', -- Text
        '', -- Method
        '', -- Function
        '', -- Constructor
        '', -- Field
        '', -- Variable
        '', -- Class
        'ﰮ', -- Interface
        '', -- Module
        '', -- Property
        '', -- Unit
        '', -- Value
        '', -- Enum
        '', -- Keyword
        '﬌', -- Snippet
        '', -- Color
        '', -- File
        '', -- Reference
        '', -- Folder
        '', -- EnumMember
        '', -- Constant
        '', -- Struct
        '', -- Event
        'ﬦ', -- Operator
        '', -- TypeParameter
      }

      -- Set up completion using nvim_cmp with LSP source
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      nvim_lsp.flow.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      nvim_lsp.tsserver.setup {
        on_attach = on_attach,
        filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
        cmd = { "typescript-language-server", "--stdio" },
        capabilities = capabilities
      }

      nvim_lsp.sourcekit.setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }

      nvim_lsp.lua_ls.setup {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          enable_format_on_save(client, bufnr)
        end,
        settings = {
          Lua = {
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = { 'vim' },
            },

            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false
            },
          },
        },
      }

      nvim_lsp.tailwindcss.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      nvim_lsp.cssls.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      nvim_lsp.elixirls.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      nvim_lsp.gopls.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      nvim_lsp.htmx.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      nvim_lsp.purescriptls.setup {
        on_attach = on_attach,
        capabilities = capabilities
      }

      -- nvim_lsp.astro.setup {
      --   on_attach = on_attach,
      --   capabilities = capabilities
      -- }

      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          underline = true,
          signs = true,
          virtual_text = { spacing = 0, prefix = "●" },
        }
      )

      -- 2024-01-01 23:08:15 +0800
      -- stop using this config as it seems to cause line content shifts
      -- Diagnostic symbols in the sign column (gutter)
      -- local signs = { Error = " ", Warn = " ", Hint = "💡", Info = " " }
      -- for type, icon in pairs(signs) do
      --   local hl = "DiagnosticSign" .. type
      --   vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      -- end

      vim.diagnostic.config({
        virtual_text = { spacing = 0, prefix = '●' },
        update_in_insert = true,
        float = {
          source = "always", -- Or "if_many"
        },
      })
    end
  },
  {
    "nvimtools/none-ls.nvim", -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
    config = function()
      local null_ls = require("null-ls")
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

      local lsp_formatting = function(bufnr)
        vim.lsp.buf.format({
          filter = function(client)
            return client.name == "null-ls"
          end,
          bufnr = bufnr,
        })
      end

      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.prettierd,
          -- null_ls.builtins.diagnostics.eslint.with({
          --   diagnostics_format = '[eslint] #{m}\n(#{c})',
          --   condition = function(utils)
          --     return utils.root_has_file({ ".eslintrc.js", ".eslintrc.json", ".eslintrc.cjs" })
          --   end,
          -- }),
          -- null_ls.builtins.diagnostics.bash,
          null_ls.builtins.diagnostics.credo,
          null_ls.builtins.formatting.mix,
        },
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                lsp_formatting(bufnr)
              end,
            })
          end
        end
      }

      vim.api.nvim_create_user_command(
        'DisableLspFormatting',
        function()
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = 0 })
        end,
        { nargs = 0 }
      )
    end
  },

  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = { "lua_ls", "tsserver" },
      })
    end
  },

  {
    "glepnir/lspsaga.nvim", -- LSP UIs
    config = function()
      local saga = require("lspsaga")

      saga.setup({
        ui = {
          winblend = 10,
          border = 'rounded',
          colors = {
            normal_bg = '#002b36'
          }
        }
      })

      -- local diagnostic = require("lspsaga.diagnostic")
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<C-j>', '<Cmd>Lspsaga diagnostic_jump_next<CR>', opts)
      vim.keymap.set('n', 'gL', '<Cmd>Lspsaga show_cursor_diagnostics<CR>', opts)
      vim.keymap.set('n', 'gB', '<Cmd>Lspsaga show_buf_diagnostics<CR>', opts)
      vim.keymap.set('n', 'gK', '<Cmd>Lspsaga hover_doc<CR>', opts)
      vim.keymap.set('n', 'gd', '<Cmd>Lspsaga lsp_finder<CR>', opts)
      -- vim.keymap.set('i', '<C-k>', '<Cmd>Lspsaga signature_help<CR>', opts)
      -- vim.keymap.set('i', '<C-k>', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
      vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>', opts)
      vim.keymap.set('n', 'gr', '<Cmd>Lspsaga rename<CR>', opts)

      -- code action
      local codeaction = require("lspsaga.codeaction")
      vim.keymap.set("n", "<leader>ca", function() codeaction:code_action() end, { silent = true })
      vim.keymap.set("v", "<leader>ca", function()
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-U>", true, false, true))
        codeaction:range_code_action()
      end, { silent = true })
    end
  },
  "L3MON4D3/LuaSnip",
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup {
        highlight = {
          enable = true,
          disable = {},
        },
        indent = {
          enable = true,
          disable = {},
        },
        ensure_installed = {
          "tsx",
          "json",
          "yaml",
          "css",
          "html",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "regex",
          "typescript",
          "javascript",
        },
        --- Automatically install missing parsers when entering buffer
        auto_install = true,

        autotag = {
          enable = true,
        },
      }

      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
    end
  },
  {
    "kyazdani42/nvim-web-devicons", -- File icons
    config = function()
      require("nvim-web-devicons").setup {
        -- your personnal icons can go here (to override)
        -- DevIcon will be appended to `name`
        override = {
        },
        -- globally enable default icons (default to false)
        -- will get overriden by `get_icons` option
        default = true
      }
    end
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require('telescope.actions')
      local builtin = require("telescope.builtin")

      local function telescope_buffer_dir()
        return vim.fn.expand('%:p:h')
      end

      -- local fb_actions = require "telescope".extensions.file_browser.actions

      telescope.setup {
        defaults = {
          mappings = {
            n = {
              ["q"] = actions.close
            },
          },
        },
        extensions = {
          file_browser = {
            theme = "ivy",
            hijack_netrw = true,
            -- mappings = {
            --   -- your custom insert mode mappings
            --   ["i"] = {
            --     ["<C-w>"] = function() vim.cmd('normal vbd') end,
            --   },
            --   ["n"] = {
            --     -- your custom normal mode mappings
            --     -- ["N"] = fb_actions.create,
            --     -- ["h"] = fb_actions.goto_parent_dir,
            --     ["/"] = function()
            --       vim.cmd('startinsert')
            --     end
            --   },
            -- },
          },
        },
      }


      vim.keymap.set('n', ';f',
        function()
          builtin.find_files({
            no_ignore = false,
            hidden = true
          })
        end)
      vim.keymap.set('n', ';r', function()
        builtin.live_grep()
      end)
      vim.keymap.set('n', ';s', function()
        builtin.grep_string()
      end)
      vim.keymap.set('n', ';b', function()
        builtin.buffers()
      end)
      vim.keymap.set('n', ';t', function()
        builtin.help_tags()
      end)
      vim.keymap.set('n', ';;', function()
        builtin.resume()
      end)
      vim.keymap.set('n', ';e', function()
        builtin.diagnostics()
      end)

      -- Load telescope-file-browser
      telescope.load_extension("file_browser")
      vim.keymap.set("n", ";af", function()
        telescope.extensions.file_browser.file_browser({
          path = "%:p:h",
          cwd = telescope_buffer_dir(),
          respect_gitignore = false,
          hidden = true,
          grouped = true,
          -- previewer = false,
          initial_mode = "normal",
          layout_config = { height = 40, width = 40 }
        })
      end)
    end
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({
        disable_filetype = { "TelescopePrompt", "vim" },
      })
    end
  },
  "windwp/nvim-ts-autotag",
  {
    "numToStr/Comment.nvim",
    opts = {
      -- add any options here
    },
    lazy = false,
    config = function()
      require("Comment").setup {
        pre_hook = function(ctx)
          -- Only calculate commentstring for tsx filetypes
          if vim.bo.filetype == 'typescriptreact' then
            local U = require('Comment.utils')

            -- Determine whether to use linewise or blockwise commentstring
            local type = ctx.ctype == U.ctype.linewise and '__default' or '__multiline'

            -- Determine the location where to calculate commentstring from
            local location = nil
            if ctx.ctype == U.ctype.blockwise then
              location = require('ts_context_commentstring.utils').get_cursor_location()
            elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
              location = require('ts_context_commentstring.utils').get_visual_start_location()
            end

            return require('ts_context_commentstring.internal').calculate_commentstring({
              key = type,
              location = location,
            })
          end
        end,
      }
    end
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        '*',
      })
    end
  },
  "folke/zen-mode.nvim",
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },
  {
    "akinsho/nvim-bufferline.lua",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "tabs",
          separator_style = 'slant',
          always_show_bufferline = false,
          show_buffer_close_icons = false,
          show_close_icon = false,
          color_icons = true
        },
        --  highlights = {
        --    separator = {
        --      fg = '#073642',
        --      bg = '#002b36',
        --    },
        --    separator_selected = {
        --      fg = '#073642',
        --    },
        --    background = {
        --      fg = '#657b83',
        --      bg = '#002b36'
        --    },
        --    buffer_selected = {
        --      fg = '#fdf6e3',
        --      bold = true,
        --    },
        --    fill = {
        --      bg = '#073642'
        --    }
        --  },
      })

      vim.keymap.set('n', '<C-m>', '<Cmd>BufferLineCycleNext<CR>', {})
      vim.keymap.set('n', '<C-n>', '<Cmd>BufferLineCyclePrev<CR>', {})
    end
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup {
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          -- Actions
          map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>')
          map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>')
          map('n', '<leader>hS', gs.stage_buffer)
          map('n', '<leader>hu', gs.undo_stage_hunk)
          map('n', '<leader>hR', gs.reset_buffer)
          map('n', '<leader>hp', gs.preview_hunk)
          map('n', '<leader>hb', function() gs.blame_line { full = true } end)
          map('n', '<leader>tb', gs.toggle_current_line_blame)
          map('n', '<leader>hd', gs.diffthis)
          map('n', '<leader>hD', function() gs.diffthis('~') end)
          map('n', '<leader>td', gs.toggle_deleted)

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
      }
    end
  },
  {
    "dinhhuy258/git.nvim", -- For git blame & browse
    config = function()
      require("git").setup({
        keymaps = {
          -- Open blame window
          blame = "<Leader>gb",
          -- Open file/folder in git repository
          browse = "<Leader>go",
        }
      })
    end
  },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  "tpope/vim-surround",
  {
    "levouh/tint.nvim", -- Dims inactive windows
    config = function()
      require("tint").setup {
        tint = -50,
        tint_background_colors = false
      }
    end
  },

  {
    "nomnivore/ollama.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    -- All the user commands added by the plugin
    cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },

    keys = {
      -- Sample keybind for prompt menu. Note that the <c-u> is important for selections to work properly.
      {
        "<leader>oo",
        ":<c-u>lua require('ollama').prompt()<cr>",
        desc = "ollama prompt",
        mode = { "n", "v" },
      },

      -- Sample keybind for direct prompting. Note that the <c-u> is important for selections to work properly.
      {
        "<leader>oG",
        ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
        desc = "ollama Generate Code",
        mode = { "n", "v" },
      },
    },

    ---@type Ollama.Config
    opts = {
      -- model = "codellama:7b-code-q4_K_M",
      -- model = "codellama:13b-code-q4_K_M",

      serve = {
        on_start = true,
        command = "ollama",
        args = { "serve" },
        stop_command = "pkill",
        stop_args = { "-SIGTERM", "ollama" },
      },
    }
  },

  -- purescript 2024-03-07 13:36:46 +0800
  -- Syntax highlighting
  { "purescript-contrib/purescript-vim" },
  -- { "jeetsukumaran/vim-pursuit" },

  -- LspConfig
  -- {
  --   "neovim/nvim-lspconfig",
  --
  --   ---@class PluginLspOpts
  --   opts = {
  --
  --     ---@type lspconfig.options
  --     servers = {
  --       -- purescriptls will be automatically installed with mason and loaded with lspconfig
  --       purescriptls = {
  --         settings = {
  --           purescript = {
  --             formatter = "purs-tidy",
  --           },
  --         },
  --       },
  --       setup = {
  --         purescriptls = function(_, opts)
  --           opts.root_dir = function(path)
  --             local util = require("lspconfig.util")
  --             if path:match("/.spago/") then
  --               return nil
  --             end
  --             return util.root_pattern("bower.json", "psc-package.json", "spago.dhall", "flake.nix", "shell.nix")(path)
  --           end
  --         end,
  --       },
  --     },
  --   },
  -- },
}
