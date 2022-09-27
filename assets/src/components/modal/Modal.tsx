import React, { PropsWithChildren, useEffect, useRef, useState } from 'react';
import { lockScroll, unlockScroll } from './utils';

interface Modal {
  modal: any;
}

export enum ModalSize {
  SMALL = 'sm',
  MEDIUM = 'md',
  LARGE = 'lg',
  X_LARGE = 'xlg',
}

export interface ModalProps {
  okLabel?: string;
  okClassName?: string;
  cancelLabel?: string;
  disableOk?: boolean;
  hideDialogCloseButton?: boolean;
  title: string;
  hideOkButton?: boolean;
  hideCancelButton?: boolean;
  onOk?: () => void;
  onCancel?: () => void;
  size?: ModalSize;
  footer?: any;
}

export const Modal = (props: PropsWithChildren<ModalProps>) => {
  const { children } = props;
  const modal = useRef<HTMLDivElement>(null);

  const okLabel = props.okLabel !== undefined ? props.okLabel : 'Insert';
  const cancelLabel = props.cancelLabel !== undefined ? props.cancelLabel : 'Cancel';
  const okClassName = props.okClassName !== undefined ? props.okClassName : 'primary';
  const size = props.size || 'lg';

  useEffect(() => {
    if (modal.current) {
      const currentModal = modal.current;
      (window as any).$(currentModal).modal('show');
      const scrollPosition = lockScroll();

      $(currentModal).on('hidden.bs.modal', (e) => {
        onCancel(e);
      });

      return () => {
        (window as any).$(currentModal).modal('hide');
        unlockScroll(scrollPosition);
      };
    }
  }, [modal]);

  const onCancel = (e: any) => {
    e.preventDefault();
    if (props.onCancel) props.onCancel();
  };

  const onOk = (e: any) => {
    e.preventDefault();
    if (props.onOk) props.onOk();
  };

  return (
    <div ref={modal} data-backdrop="true" className="modal">
      <div className={`modal-dialog modal-dialog-centered modal-${size}`} role="document">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">{props.title}</h5>
            {props.hideDialogCloseButton === true ? null : (
              <button type="button" className="close" onClick={onCancel} data-dismiss="modal">
                <span aria-hidden="true">&times;</span>
              </button>
            )}
          </div>
          <div className="modal-body">{children}</div>
          <div className="modal-footer">
            {props.footer ? (
              props.footer
            ) : (
              <>
                {props.hideCancelButton === true ? null : (
                  <button
                    type="button"
                    className="btn btn-link"
                    onClick={onCancel}
                    data-dismiss="modal"
                  >
                    {cancelLabel}
                  </button>
                )}
                {props.hideOkButton === true ? null : (
                  <button
                    disabled={props.disableOk}
                    type="button"
                    onClick={onOk}
                    className={`btn btn-${okClassName}`}
                  >
                    {okLabel}
                  </button>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
