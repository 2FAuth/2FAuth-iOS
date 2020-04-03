/*
 * https://github.com/mattrubin/Authenticator/pull/234/files#diff-8ae18737b2162fa6b5632a5bc6cee788
 *
 * Created by Beau Collins
 * The MIT License (MIT)
 *
 * Copyright (c) 2013-2019 Authenticator authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

function setPassword(password) {
    return function (inputNode) {
        inputNode.value = password;
    }
}

/*
 * Javascript files used for action processing are expected to
 * define a global variable of ExtensionPreprocessingJS that can
 * have two methods/functions:
 *
 * - run: executed by the action extension when it wants to get data from the webpage
 * - finalize: executed by the action extension when it completes its activity
 */
var ExtensionPreprocessingJS = {
    /*
     * When an action is initialized it can ask to run this script
     * to provide context to the action
     */
    run: function(arguments) {
        // provide the current URI
        // the share extension can use this information to
        // highlight what it thinks is the correct password
        arguments.completionFunction({
            baseURI: document.baseURI
        });
    },
    /*
     * Called when the action has completed picking a password
     */
    finalize: function(arguments) {
        // usually OTP fields are type=tel, but we can't assume this is the case
        // as a fallback, the extension should copy the password to the clipboard
        // as well
        const potentialFields = document.querySelectorAll('input[autocomplete=one-time-code],input[type=text],input[type=tel]');
        // Use the Array forEach iterator to set the input's value to
        // the provided password
        [].forEach.call(potentialFields, setPassword(arguments.password))
    }
};
