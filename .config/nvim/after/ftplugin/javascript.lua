-- JavaScript filetype configuration for P5.js compatibility
-- Addresses "Invalid 'col': out of range" errors with inlay hints

-- Disable inlay hints for JavaScript files to prevent LSP positioning errors
vim.lsp.inlay_hint.enable(false, { bufnr = 0 })

-- Set up safer LSP configuration for JavaScript/P5.js files
local function setup_js_lsp()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
        if client.name == "typescript-tools" or client.name == "vtsls" or client.name == "tsserver" then
            -- Disable problematic features that can cause column range errors
            if client.server_capabilities then
                client.server_capabilities.inlayHintProvider = false
            end

            -- Configure safer settings for P5.js
            if client.config and client.config.settings then
                local settings = client.config.settings
                if settings.typescript then
                    settings.typescript.inlayHints = {
                        includeInlayParameterNameHints = "none",
                        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                        includeInlayFunctionParameterTypeHints = false,
                        includeInlayVariableTypeHints = false,
                        includeInlayPropertyDeclarationTypeHints = false,
                        includeInlayFunctionLikeReturnTypeHints = false,
                        includeInlayEnumMemberValueHints = false,
                    }
                end
            end
        end
    end
end

-- Apply configuration when LSP clients attach
vim.api.nvim_create_autocmd("LspAttach", {
    buffer = 0,
    callback = setup_js_lsp,
})

-- Also apply immediately if LSP is already attached
setup_js_lsp()

-- P5.js specific settings
-- Set comment string for P5.js files
vim.bo.commentstring = "// %s"

-- Ensure proper indentation for P5.js
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.expandtab = true
