import * as Headless from '@headlessui/react'
import * as React from 'react'

// headlessUI is a collection of nice unstyled UI components that are super
// accessible and play nicely with Tailwind CSS.

// MENU (DROPDOWN) -------------------------------------------------------------
// https://headlessui.com/react/menu

export const menu = lustre_component(Headless.Menu)
export const menu_button = lustre_component(Headless.Menu.Button)
export const menu_items = lustre_component(Headless.Menu.Items)
export const menu_item = lustre_component(Headless.Menu.Item)

// LISTBOX (SELECT) ------------------------------------------------------------
// https://headlessui.com/react/listbox

export const listbox = lustre_component(Headless.Listbox)
export const listbox_button = lustre_component(Headless.Listbox.Button)
export const listbox_options = lustre_component(Headless.Listbox.Options)
export const listbox_option = lustre_component(Headless.Listbox.Option)
export const listbox_label = lustre_component(Headless.Listbox.Label)

// COMBOBOX (AUTOCOMPLETE) -----------------------------------------------------
// https://headlessui.com/react/combobox

export const combobox = lustre_component(Headless.Combobox)
export const combobox_input = lustre_component(Headless.Combobox.Input)
export const combobox_button = lustre_component(Headless.Combobox.Button)
export const combobox_options = lustre_component(Headless.Combobox.Options)
export const combobox_option = lustre_component(Headless.Combobox.Option)
export const combobox_label = lustre_component(Headless.Combobox.Label)

// SWITCH (TOGGLE) -------------------------------------------------------------
// https://headlessui.com/react/switch

export const switch_ = lustre_component(Headless.Switch)

// DISCLOSURE ------------------------------------------------------------------
// https://headlessui.com/react/disclosure

export const disclosure = lustre_component(Headless.Disclosure)
export const disclosure_button = lustre_component(Headless.Disclosure.Button)
export const disclosure_panel = lustre_component(Headless.Disclosure.Panel)

// DIALOG (MODAL) --------------------------------------------------------------
// https://headlessui.com/react/dialog

export const dialog = lustre_component(Headless.Dialog)
export const dialog_panel = lustre_component(Headless.Dialog.Panel)
export const dialog_title = lustre_component(Headless.Dialog.Title)
export const dialog_description = lustre_component(Headless.Dialog.Description)

// POPOVER ---------------------------------------------------------------------
// https://headlessui.com/react/popover

export const popover = lustre_component(Headless.Popover)
export const popover_button = lustre_component(Headless.Popover.Button)
export const popover_panel = lustre_component(Headless.Popover.Panel)

// RADIO GROUP -----------------------------------------------------------------
// https://headlessui.com/react/radio-group

export const radio_group = lustre_component(Headless.RadioGroup)
export const radio_group_label = lustre_component(Headless.RadioGroup.Label)
export const radio_group_option = lustre_component(Headless.RadioGroup.Option)

// TABS ------------------------------------------------------------------------
// https://headlessui.com/react/tabs

export const tab_group = lustre_component(Headless.Tab.Group)
export const tab_list = lustre_component(Headless.Tab.List)
export const tab = lustre_component(Headless.Tab)
export const tab_panels = lustre_component(Headless.Tab.Panels)
export const tab_panel = lustre_component(Headless.Tab.Panel)

// TRANSITION ------------------------------------------------------------------
// https://headlessui.com/react/transition

export const transition = lustre_component(Headless.Transition)

// UTILS -----------------------------------------------------------------------

function lustre_component(component) {
    return (attributes, children) => (dispatch) =>
        React.createElement(component,
            to_props(attributes, dispatch),
            ...children.toArray().map((child) => typeof child === "function" ? child(dispatch) : child)
        )
}

// This is vendored directly from the lustre ffi module found over here:
// https://github.com/hayleigh-dot-dev/gleam-lustre/blob/main/src/ffi.mjs#L102
const to_props = (attributes, dispatch) => {
    const capitalise = s => s && s[0].toUpperCase() + s.slice(1)

    return Object.fromEntries(
        attributes.toArray().map(attr => {
            // The constructors for the `Attribute` type are not public in the
            // gleam source to prevent users from constructing them directly.
            // This has the unfortunate side effect of not letting us `instanceof`
            // the constructors to pattern match on them and instead we have to
            // rely on the structure to work out what kind of attribute it is.
            //
            // This case handles `Attribute` and `Property` variants.
            if ('name' in attr && 'value' in attr) {
                return [attr.name, typeof attr.value === 'function'
                    // So-called "render props" are function props that return
                    // React components. We need to also call them with `dispatch`
                    // for them to work in lustre.
                    ? props => render_prop(attr.value(props), dispatch)
                    : attr.value
                ]
            }

            // This case handles `Event` variants.
            else if ('name' in attr && 'handler' in attr) {
                return ['on' + capitalise(attr.name), (e) => attr.handler(e, dispatch)]
            }

            // This should Never Happen™️ but if it does we don't want everything
            // to explode, so we'll print a friendly error, ignore the attribute
            // and carry on as normal.
            else {
                console.warn([
                    '[lustre] Oops, I\'m not sure how to handle attributes with ',
                    'the type "' + attr.constructor.name + '". Did you try calling ',
                    'this function from JavaScript by mistake?',
                    '',
                    'If not, it might be an error in lustre itself. Please open ',
                    'an issue at https://github.com/hayleigh-dot-dev/gleam-lustre/issues'
                ].join('\n'))

                return []
            }
        })
    )
}

const render_prop = (children, dispatch) => {
    if (typeof children === 'function') {
        return [children(dispatch)]
    }

    if (typeof children === 'object') {
        return children.toArray().map(child => typeof child === 'function'
            ? child(dispatch)
            : child
        )
    }

    return children
}